# JazzCash Flutter Package Example

This example demonstrates how to use the JazzCash Flutter package for both mobile wallet and card payments.

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure JazzCash Credentials

In `lib/main.dart`, update the initialization with your credentials:

```dart
jazzCash = JazzCashService.initialize(
  merchantId: 'YOUR_MERCHANT_ID',     // Replace with your merchant ID
  password: 'YOUR_PASSWORD',          // Replace with your password
  integritySalt: 'YOUR_INTEGRITY_SALT', // Replace with your integrity salt
  isProduction: false,                // Set to true for production
);
```

### 3. Run the Example

```bash
flutter run
```

## Features Demonstrated

### 🔐 **Configuration**
- Sandbox vs Production environment setup
- Credential management
- Environment switching

### 📱 **Mobile Wallet Payment**
- Form validation (mobile number, CNIC, amount)
- Payment processing with error handling
- Success/failure response handling
- Transaction status checking

### 💳 **Card Payment**
- WebView-based card payment flow
- 3D Secure authentication support
- Payment result handling
- Cancellation handling

### 🔍 **Transaction Management**
- Real-time transaction status checking
- Payment response validation
- Error handling and user feedback

## Test Data

The example app comes pre-filled with test data for easy testing:

- **Mobile Number**: 03001234567
- **CNIC**: 1234567890123
- **Amount**: 100 PKR
- **Description**: Test Payment

## Important Notes

### For Testing (Sandbox)
1. Use sandbox credentials provided by JazzCash
2. Keep `isProduction: false`
3. Test with provided test mobile numbers and CNICs

### For Production
1. Update credentials to production values
2. Set `isProduction: true`
3. Update return URL to your actual domain
4. Test thoroughly before going live

## UI Components

### Payment Form
- Amount input with validation
- Description field
- Mobile number input (for mobile wallet)
- CNIC input (for mobile wallet)

### Payment Methods
- Mobile Wallet button (green)
- Card Payment button (blue)
- Loading states
- Success/error dialogs

### Status Checking
- Transaction status inquiry
- Real-time status updates
- Color-coded status indicators

## Error Handling

The example demonstrates comprehensive error handling for:
- Validation errors
- Network errors
- JazzCash API errors
- Payment failures
- Timeout issues

## Customization

You can customize the example by:
- Modifying the UI theme and colors
- Adding your app branding
- Implementing custom validation rules
- Adding additional payment fields
- Integrating with your backend API

## Screenshots

The example app includes:
- Clean Material Design interface
- Intuitive payment flow
- Clear success/error feedback
- Professional loading states
- Responsive layout

## Next Steps

After testing the example:
1. Integrate the package into your app
2. Customize the UI to match your design
3. Implement backend integration
4. Add transaction logging
5. Set up production credentials
6. Test thoroughly before release