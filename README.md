### Reimbursement App

This is a full-stack mobile application built with Flutter to simplify and automate the employee reimbursement process. The app allows employees to quickly submit expense claims by taking a picture of a bill, which uses OCR to pre-fill form details, reducing manual data entry and speeding up the approval workflow.

-----

### Key Features

  * **Custom Authentication:** Secure employee login and role-based access management.
  * **Bill Submission:** Users can submit new bills by selecting an image from their gallery, using their camera, or uploading a PDF.
  * **Intelligent OCR:** Utilizes **Google ML Kit** to automatically recognize and extract key data like the amount and date from bill images, pre-filling the submission form.
  * **Real-time Status Tracking:** Employees can view their last 5 recent submissions directly on their home screen.
  * **Full History:** A dedicated history page displays a complete list of all past submissions.
  * **Admin Workflow (Planned):** The backend is structured to support an administrator dashboard for reviewing, approving, or rejecting claims.

-----

### Tech Stack

  * **Frontend:** **Flutter**
  * **Backend:** **Supabase**
      * **Database:** PostgreSQL for storing all user and bill data.
      * **Storage:** Secure cloud storage for all uploaded receipt images and PDFs.
      * **Authentication:** Custom logic for user login and role management.
  * **Machine Learning:** **Google ML Kit** for client-side text recognition (OCR).

-----

### Getting Started

To get a copy of this project up and running locally, follow these steps.

**Prerequisites**

  * Flutter SDK installed
  * A Supabase project with a PostgreSQL database and Storage bucket

**Setup**

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/vrishanknehru/reimbursement-app.git
    cd reimbursement-app
    ```
2.  **Configure Supabase:**
      * In your Supabase project dashboard, get your **Project URL** and **Anon Key**.
      * Open `main.dart` and replace the placeholder values in `Supabase.initialize` with your own credentials.
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```
    This will build and run the app on your connected device or emulator.

-----

### Project Status & Future Plans

This project is a work in progress. The current focus is on building a robust employee-side experience and the core backend for submissions. The next major milestone is to finalize the admin dashboard and implement an email notification system for approvals using a Supabase Edge Function.

-----

### Made with love by Vrishank Nehru

*Feel free to star the repo if you found it useful\!*
