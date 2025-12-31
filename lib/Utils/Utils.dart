import 'package:flutter/material.dart';

class Utils {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static int selectIndex = 0;

  static String baseUrl = 'http://10.0.2.2:9091/api';
  static String registerUrl = "/Auth/register";
  static String loginUrl = "/Auth/login";
  static String google_Url = "/Auth/google";
  static String forgotPasswordUrl = "/Auth/forgot-password";
  static String verify_email_url = "/Auth/verify";
  static String reset_password_url = "/Auth/reset-password";
  static String verify_otp_url = "/Auth/verify-otp";
  static String resend_otp_url = "/Auth/resend-otp";
  static String refresh_token_url = "/Auth/refresh";
  static String logout_url = "/Auth/logout";
  static String rssFetchUrl = "/Rss/fetch";
}