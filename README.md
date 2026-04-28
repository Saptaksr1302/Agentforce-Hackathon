# 🛍️ Retail Store Planogram Management System

## 📌 Overview
This project is built using **Salesforce Apex, Triggers, and Lightning Web Components (LWC)** to streamline retail execution for field sales representatives.

It enables:
- Matching **Retail Stores** with **In-Store Locations**
- Managing **Planogram Images**
- Allowing sales reps to upload shelf images
- Visualizing execution through a **custom LWC dashboard**

---

## 🚀 Features

### 🔗 Retail Store ↔ In-Store Location Mapping
- Automatically associates retail stores with their respective in-store locations
- Ensures accurate tracking of product placement

### 🖼️ Planogram Image Management
- Upload and store planogram images against in-store locations
- Helps define expected shelf layouts

### 📷 Sales Rep Image Upload
- Sales reps can upload real-time shelf images
- Images are linked to:
  - Retail Store
  - In-Store Location

### 📊 LWC Dashboard
- Interactive dashboard for sales reps
- Provides:
  - Image upload functionality
  - Easy navigation between stores and locations

---

## 🏗️ Architecture

### Backend (Apex)
- **Apex Classes**
  - Business logic for mapping, validation, and image handling
- **Triggers**
  - Automate record creation and updates
  - Maintain data consistency between objects

### Frontend (LWC)
- Dashboard UI
- Image upload components
- Data visualization components

---

## 📂 Project Structure

```
force-app/
│── main/
│   ├── default/
│   │   ├── classes/              # Apex Classes
│   │   ├── triggers/             # Apex Triggers
│   │   ├── lwc/                  # Lightning Web Components
```

---

## ⚙️ Setup Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```

2. Authorize your Salesforce org:
   ```bash
   sfdx auth:web:login
   ```

3. Deploy the project:
   ```bash
   sfdx force:source:deploy -p force-app
   ```

4. Add LWC components to Lightning Pages:
   - Home Page

---

## 🧑‍💼 Usage Flow

1. Create or select a **Retail Store**
2. Map **In-Store Locations**
3. Upload **Planogram Image**
4. Sales rep visits store and uploads **actual shelf image**
5. Upload planogram image to the in-store locations via **Mobile-First Rep Dashboard**
6. Agent validate the retail store and in-store location
7. Analyzes shelf image and gives response.
8. Create **Shelf Audit** record based on analysis
9. Create **Visit & Assessment Task** related to the shelf audit

---

## 🔐 Permissions

Ensure Einstein Agent user has access to:
- Retail Store object
- In-Store Location object
- Files (ContentDocument)
- Apex Classes & LWC Components
- Shelf Audit object
- Visit object
- Assessment Task object
- Shelf Action object
- Shelf Number Audit object

---

## 📸 Future Enhancements

- AI-based image comparison while sending through whatsapp to the agent (Planogram vs Actual)
- Einstein Vision API for shelf image analysis after image is sent to agent through whatsapp
- Advanced analytics dashboard

---

## 📄 License
This project is for agentforce hackathon challenge.
