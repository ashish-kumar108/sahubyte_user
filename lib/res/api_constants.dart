class ApiConstants {
  static const technicianBaseUrl =
      "https://techcanopusdemo.com/sahubyte/TechnicianApi/";
  static const userBaseUrl = "https://techcanopusdemo.com/sahubyte/userApi/";

  // Technician APIs
  static const technicianGetAssignedEnquiries =
      "${technicianBaseUrl}getAssignedEnquiries";
  static const technicianGetJobCard = "${technicianBaseUrl}getJobCard";

  // User APIs
  static const userLogin = "${userBaseUrl}login";
  static const userSendOtpLogin = "${userBaseUrl}sendOtpLogin";
  static const userSignupOtp = "${userBaseUrl}signupOtp";
  static const userSignup = "${userBaseUrl}signup";
  static const userGetData = "${userBaseUrl}getData";
  static const userGetBrands = "${userBaseUrl}getBrands";
  static const userGetProblems = "${userBaseUrl}getProblems";
  static const userCreateEnquiry = "${userBaseUrl}createEnquiry";
  static const userGetEnquiries = "${userBaseUrl}getEnquiries";
  static const userCreateFunction = "${userBaseUrl}createFunction";
  static const userDetail = "${userBaseUrl}userDetail";
}
