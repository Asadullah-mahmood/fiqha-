import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quranpak/utils/AppTheme.dart';

class Notificationscreen extends StatefulWidget {
  const Notificationscreen({super.key});

  @override
  State<Notificationscreen> createState() => _NotificationscreenState();
}

class _NotificationscreenState extends State<Notificationscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
    //    backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: -10,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(child: RefreshIndicator(
        onRefresh: () {
          return Future.delayed(Duration(seconds: 2));
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.notifications_off_outlined, color: Colors.grey, size: 40,)),

              SizedBox(height: 20,),

              Text('No Notification Found!', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold), textScaler: TextScaler.linear(1),),

              SizedBox(height: 10,),


              Text('Looking for new notifications and alerts.', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400), textScaler: TextScaler.linear(1),),

            ],
          ),
        ),
      )),
    );
  }
}