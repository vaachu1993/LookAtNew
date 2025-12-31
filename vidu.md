import 'package:flutter/material.dart';

class Utils{
    static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    static String userName = "";
    static int selectIndex = 0;
    static String baseUrl = "https://firstreddog41.conveyor.cloud";
    static String slideUrl = "/api/Product/get-slide-product";
    static String allProductUrl = "/api/Product/get-all-product";
}

--------------------------------------------------

import 'package:flutter/material.dart';

import '../Utils.dart';

class BottomNavigationBarComponent extends StatelessWidget{
    void tabItemClick(int value){
        Utils.selectIndex = value;
        BuildContext context = Utils.navigatorKey.currentContext!;
        if( value == 0){
            Navigator.pushNamed(context, '/home');
        }
        if(value == 1){
            Navigator.pushNamed(context, '/product');
        }
        if(value == 2){
            Navigator.pushNamed(context, '/chat');
    }
        if(value == 3){
            Navigator.pushNamed(context, '/productDetail');
        }
    }
    @override
    Widget build(BuildContext context) {
        // TODO: implement build
        return BottomNavigationBar(
            onTap: (value) {
                return tabItemClick(value);
            },
            backgroundColor: Colors.green,
            selectedItemColor: Colors.orange,
            currentIndex: Utils.selectIndex,
            type: BottomNavigationBarType.fixed,
            items: [
                BottomNavigationBarItem(icon: Icon(Icons.home,),label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.add_card,),label: "Product"),
                BottomNavigationBarItem(icon: Icon(Icons.chat,),label: "Chat"),
                BottomNavigationBarItem(icon: Icon(Icons.adb,),label: "DT"),
            ]);
    }
}

---------------------------------------------------
import 'package:demo_22dthc2/Views/ChatView.dart';
import 'package:demo_22dthc2/Views/HomeView.dart';
import 'package:demo_22dthc2/Views/LoginView.dart';
import 'package:demo_22dthc2/Views/ProductView.dart';
import 'package:flutter/material.dart';


import 'Utils.dart';
import 'Views/ProductDetailView.dart';


void main() {
    runApp(MaterialApp(
        navigatorKey: Utils.navigatorKey,
        title: "My app",
        initialRoute: '/',
        routes: {
            '/': (context)
            => LoginView(),
            '/home': (context)
            => HomeView(),
            '/chat': (context)
            => ChatView(),
            '/product': (context)
            => ProductView(),
            '/productDetail': (context){
                var args = ModalRoute.of(context)!.settings.arguments as Map;
                return ProductDetailView((args["Id"] as int));
            } 
        }
    ));
}




