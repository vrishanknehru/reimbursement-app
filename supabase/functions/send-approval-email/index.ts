// supabase/functions/send-approval-email/index.ts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
// Using specific import for Resend for better type inference if available,
// or use the general import as you did if that's what works.
import { Resend } from 'npm:resend@1.1.0'; // Correct way to import npm modules in Deno
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'; // Supabase client for DB/Storage access

console.log('Sending Approval Email function started!');

serve(async (req) => {
  // Initialize Supabase client with service_role_key for backend access
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', // Use service_role_key
    {
      auth: {
        persistSession: false, // Don't persist session in Edge Function
        autoRefreshToken: false, // Prevent token refresh logic in serverless context
        detectSessionInUrl: false, // Prevent session detection from URL in serverless context
      },
    }
  );

  // Initialize Resend client with API Key
  const resend = new Resend(Deno.env.get('RESEND_API_KEY') ?? '');

  // Check for POST method, as triggers send POST requests
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  // Extract data from the database trigger payload
  const payload = await req.json();
  const bill = payload.record; // 'record' contains the new (updated) bill row data

  if (!bill) {
    console.error('No bill record found in payload from trigger.');
    return new Response('No bill record found', { status: 400 });
  }

  // Extract bill details and URLs
  const billId = bill.id; // <--- FIX: billId was undefined in original code
  const employeeId = bill.user_id;
  const billPurpose = bill.purpose || 'Reimbursement Request';
  const billAmount = (bill.amount as number)?.toFixed(2) || 'N/A'; // <--- FIX: Ensure amount is number and format
  const billDate = bill.date || 'N/A';
  const billStatus = bill.status || 'N/A';
  const originalImageUrl = bill.image_url; // URL of the original uploaded image/PDF
  const generatedPdfUrl = bill.generated_pdf_url; // URL of the generated PDF
  const adminNotes = bill.admin_notes || '';

  // Check if status is approved (optional, but good for safety if trigger WHEN is broad)
  if (billStatus.toLowerCase() !== 'approved') {
    console.log(`Bill ${billId} status is '${billStatus}', not sending email.`);
    return new Response(JSON.stringify({ message: 'Bill not approved, no email sent' }), {
      status: 200, // Return 200 as it's not an error, just no action
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // 1. Fetch employee's email and username from the 'users' table
  const { data: employeeProfile, error: profileError } = await supabaseClient
    .from('users') // Your custom users table
    .select('email, username')
    .eq('id', employeeId)
    .single();

  if (profileError || !employeeProfile) {
    console.error('Error fetching employee profile:', profileError?.message || 'Profile not found');
    return new Response('Employee profile not found', { status: 500 });
  }

  const employeeEmail = employeeProfile.email;
  const employeeUsername = employeeProfile.username || employeeProfile.email;
  const dummyEmail = Deno.env.get('DUMMY_EMAIL_ID') ?? 'test@example.com'; 

  // --- FIX for Resend attachments in Deno ---
  // Resend expects base64 content. Deno's 'btoa' works on strings, not directly on Uint8Array.
  // Use Deno's build-in `Buffer` (from Node.js compatibility layer) or
  // more reliably, convert Uint8Array to string then base64.
  // The npm 'buffer' package can also be used: `npm i buffer`
  // For simplicity, let's use TextDecoder/TextEncoder with btoa for now.

  // Helper function to download file from Supabase Storage and base64 encode it
  const downloadFile = async (url: string, suggestedFilename: string) => {
    try {
      // Supabase Storage URLs typically look like:
      // https://<project_ref>.supabase.co/storage/v1/object/public/<bucket_name>/<path_in_bucket>
      const urlParts = url.split('/storage/v1/object/public/receipts/');
      if (urlParts.length < 2) {
        console.error('Invalid storage URL format for download:', url);
        return null;
      }
      const pathInBucket = urlParts[1];

      const { data: blob, error: downloadError } = await supabaseClient.storage
        .from('receipts')
        .download(pathInBucket);

      if (downloadError) {
        console.error(`Error downloading ${suggestedFilename}:`, downloadError.message);
        return null;
      } else if (blob) {
        const arrayBuffer = await blob.arrayBuffer();
        // Deno's btoa function expects a string. Convert ArrayBuffer to string first.
        const base64Content = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));

        return {
          filename: suggestedFilename,
          content: base64Content, // Base64 encoded string
        };
      }
    } catch (e) {
      console.error(`Exception during ${suggestedFilename} download:`, e);
      return null;
    }
    return null;
  };

  // Prepare attachments array
  const attachments = [];

  // 2. Download Original Bill Attachment (if URL exists)
  if (originalImageUrl) {
    const fileExtension = originalImageUrl.split('.').pop() || 'file'; // Get file extension
    const originalAttachment = await downloadFile(
        originalImageUrl,
        `Original_Bill_${billId.substring(0, 6)}.${fileExtension}`
    );
    if (originalAttachment) attachments.push(originalAttachment);
  }

  // 3. Download Generated PDF Attachment (if URL exists)
  if (generatedPdfUrl) {
    const generatedAttachment = await downloadFile(
        generatedPdfUrl,
        `Generated_Claim_${billId.substring(0, 6)}.pdf`
    );
    if (generatedAttachment) attachments.push(generatedAttachment);
  }

  // 4. Send Email using Resend
  try {
    const { data, error } = await resend.emails.send({
      from: 'Reimbursement App <onboarding@resend.dev>', // IMPORTANT: Replace with YOUR verified Resend domain/sender (e.g., 'yourname@yourdomain.com')
      to: [dummyEmail], // Sending to dummy email for PoC. For real use, change to [employeeEmail]
      subject: `Your Reimbursement Bill for ${billPurpose} has been ${billStatus}!`,
      html: `
        <p>Dear ${employeeUsername},</p>
        <p>Your reimbursement request (Purpose: ${billPurpose}, Amount: ₹${billAmount}) has been processed.</p>
        <p>The status is now: <strong>${billStatus.toUpperCase()}</strong>.</p>
        ${adminNotes ? `<p>Admin Remarks: ${adminNotes}</p>` : ''}
        <p>Thank you for using the Reimbursement App.</p>
      `,
      attachments: attachments.length > 0 ? attachments : undefined, // Attach files if any
    });

    if (error) {
      console.error('Error sending email:', error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    console.log('Email sent successfully:', data);
    return new Response(JSON.stringify({ message: 'Email sent' }), {
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (emailError) {
    console.error('Caught exception during email send:', emailError);
    return new Response(JSON.stringify({ error: 'Failed to send email due to exception' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});