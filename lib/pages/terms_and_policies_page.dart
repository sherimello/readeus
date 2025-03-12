import 'package:flutter/material.dart';
import 'package:get/get.dart';
class TermsAndPolicies extends StatelessWidget {
  const TermsAndPolicies({super.key});

  @override
  Widget build(BuildContext context) {
    
    var size = MediaQuery.of(context).size;
    var appBarHeight = AppBar().preferredSize.height;
    var topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xffAAD0F9),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        title: Text("Terms & Policies"),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(11,11,11,0),
          child: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(55)
            ),
            child: Padding(
              padding: const EdgeInsets.all(21.0),
              child: RawScrollbar(
                  trackVisibility: true,
                  padding: EdgeInsets.only(top: appBarHeight),
                  thickness: 5,
                  thumbColor: const Color(0xff1d3f5e),
                  radius: const Radius.circular(3.0),
                  interactive: true,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("""By accessing and using the services provided by [Your Company Name], you agree to comply with these Terms and Conditions, effective as of [Insert Date]. Our services, including cargo container handling, are available to users who are at least 18 years old and legally able to enter into a contract. You agree to use our services in compliance with applicable laws, and any misuse may result in suspension or termination of access. Pricing for our services is subject to change, and payment is due as specified in your agreement. We are not liable for indirect, special, or consequential damages arising from the use or inability to use our services. We reserve the right to terminate or suspend your access at our discretion. These Terms and Conditions are governed by the laws of [Your Country/Region], and any modifications will be posted on this page. We value your privacy and are committed to protecting your personal data as outlined in our Privacy Policy. We collect personal information such as your name, email, phone number, and payment details, which we use to provide services, communicate with you, and improve your experience. Your data is not sold or rented, but may be shared with trusted partners who assist us in service delivery. We take reasonable precautions to protect your personal data, and you have the right to access, update, or request deletion of your information. Our website uses cookies to enhance your experience, and you can disable them through your browser settings. We may update this Privacy Policy periodically, and the changes will take effect immediately upon posting. For any questions about these terms or our privacy practices, please contact us at [email address]."""),
                    ),
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
