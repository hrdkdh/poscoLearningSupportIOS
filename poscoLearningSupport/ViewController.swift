//
//  ViewController.swift
//  poscoLearningSupport
//
//  Created by hrdkdh on 2020/03/02.
//  Copyright © 2020 hrdkdh. All rights reserved.
//

import UIKit
import WebKit
import CoreBluetooth
import CoreLocation

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, CLLocationManagerDelegate {

    @IBOutlet var webView: WKWebView!
    
    var locationManager: CLLocationManager = CLLocationManager()
    var beaconData:Array<Dictionary<String, Any>>=[]
    var beaconCheckedMajorMinor: String = ""
    var gpsResultStr: String = ""
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func loadView() {
        if #available(iOS 12, *) {

        } else {
            super.loadView()
        }
        print("뷰를 로드합니다...")

        //webView = WKWebView(frame: self.view.frame)
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let url = URL(string: "http://app.poscohrd.com:8000")
        let request = URLRequest(url: url!)
        
        webView.load(request)
        print(request)
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() //권한 요청
    }

    //status bar 배경색 바꾸기
    override func viewDidAppear(_ animated: Bool) {
        
        if #available(iOS 13, *)
        {
            let statusBar = UIView(frame: (UIApplication.shared.keyWindow?.windowScene?.statusBarManager?.statusBarFrame)!)
            statusBar.backgroundColor = UIColor.init(displayP3Red: 35/255, green: 80/255, blue: 123/255, alpha: 1)
            UIApplication.shared.keyWindow?.addSubview(statusBar)
        } else {
            if #available(iOS 10, *) {
                UIApplication.shared.statusBarView?.backgroundColor = UIColor.init(displayP3Red: 35/255, green: 80/255, blue: 123/255, alpha: 1)
            }
        }
    }
    
    /******************블루투스 관련 메쏘드*******************/
    func startScanning() {
        print("비콘탐색 시작")
        print("GPS탐색 시작")
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //위치 업데이트
        locationManager.startUpdatingLocation()

        //print(beaconArrStr)
        for beaconInfo in self.beaconData {
            print("검색하려는 대상 비콘의 정보 : \(beaconInfo)")
            var thisUuid:UUID!
            var thisMajor:UInt16!
            var thisMinor:UInt16!
            var thisIdentifier:String!
            for (key, value) in beaconInfo as! [String : String] {
                if (key=="uuid") {
                    thisUuid = UUID(uuidString: value)!
                } else if (key=="major") {
                    thisMajor = UInt16(value)!
                } else if (key=="minor") {
                    thisMinor = UInt16(value)!
                } else if (key=="identifier") {
                    thisIdentifier = String(value)
                }
            }
            if #available(iOS 13, *) {
                self.locationManager.startMonitoring(for : CLBeaconRegion(uuid: thisUuid, major: thisMajor, minor: thisMinor, identifier: thisIdentifier))
                self.locationManager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: thisUuid, major: thisMajor, minor: thisMinor))
            } else {
                let beaconRegion = CLBeaconRegion(proximityUUID: thisUuid, major: thisMajor!, minor: thisMinor!, identifier: thisIdentifier)
                locationManager.startMonitoring(for: beaconRegion)
                locationManager.startRangingBeacons(in: beaconRegion)
            }
        }
        self.stopScanning()
    }
    
    func stopScanning() {
        let when = DispatchTime.now() + 10 // change 10 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            for beaconInfo in self.beaconData {
                var thisUuid:UUID!
                var thisMajor:UInt16!
                var thisMinor:UInt16!
                var thisIdentifier:String!
                for (key, value) in beaconInfo as! [String : String] {
                    if (key=="uuid") {
                        thisUuid = UUID(uuidString: value)!
                    } else if (key=="major") {
                        thisMajor = UInt16(value)!
                    } else if (key=="minor") {
                        thisMinor = UInt16(value)!
                    } else if (key=="identifier") {
                        thisIdentifier = String(value)
                    }
                }
                if #available(iOS 13, *) {
                    self.locationManager.stopMonitoring(for : CLBeaconRegion(uuid: thisUuid, major: thisMajor, minor: thisMinor, identifier: thisIdentifier))
                    self.locationManager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: thisUuid, major: thisMajor, minor: thisMinor))
                } else {
                    let beaconRegion = CLBeaconRegion(proximityUUID: thisUuid, major: thisMajor!, minor: thisMinor!, identifier: thisIdentifier)
                    self.locationManager.stopMonitoring(for: beaconRegion)
                    self.locationManager.stopRangingBeacons(in: beaconRegion)
                }
            }
            print("비콘탐색 종료")
            print("GPS탐색 종료")
            self.locationManager.stopUpdatingLocation()
            self.chulCheck()
        }
    }
    
    //GPS 탐색이 시작되면...
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //위치가 업데이트될때마다
        if let coor = manager.location {
            //위도, 경도 가져오기
            let latitude = coor.coordinate.latitude
            let longitude = coor.coordinate.longitude
            let distanceBetween : CLLocationDistance = coor.distance(from: coor)
            gpsResultStr = latitude.description+"_"+longitude.description+"_"+String(distanceBetween)
            print(gpsResultStr)
        }
    }

    //비콘 감지 성공하면...
    @available(iOS 13, *)
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if beacons.count > 0 {
            print("감지된 비콘 정보 : \(beacons)")
            self.beaconCheckedMajorMinor=beacons[0].major.stringValue+"_"+beacons[0].minor.stringValue
        } else {
            print("감지된 비콘 정보 : 감지되지 않음!")
        }
    }
    
    //비콘 감지 실패하면...
    @available(iOS 13, *)
    func locationManager(_ manager: CLLocationManager, didFailRangingFor: CLBeaconIdentityConstraint, error: Error) {
        print("에러")
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            print("감지된 비콘 정보 : \(beacons)")
            beaconCheckedMajorMinor=beacons[0].major.stringValue+"_"+beacons[0].minor.stringValue
        } else {
            print("감지된 비콘 정보 : 감지되지 않음!")
        }
    }
    
    func chulCheck() {
        let c=getCookieInfo(cookieName: "c")
        let i=getCookieInfo(cookieName: "i")
        let selectedCuriNo=getCookieInfo(cookieName: "selectedCuriNo")
        let selectedChaNo=getCookieInfo(cookieName: "selectedChaNo")
        let majorMinorStr=self.beaconCheckedMajorMinor
        
        let date = Date()
        let dateFromatter  = DateFormatter()
        dateFromatter.dateFormat = "yyyy-MM-dd"
        let nowDateYmd = dateFromatter.string(from: date)
        
        print(majorMinorStr)
        
        var chulCheckResults=""
        let urlStr="http://app.poscohrd.com:8000/?ca=setChulSign&c="+c+"&i="+i+"&selectedCuriNo="+selectedCuriNo+"&selectedChaNo="+selectedChaNo+"&chulDate="+nowDateYmd+"&majorMinor="+majorMinorStr+"&gps="+gpsResultStr

        print(urlStr)
        let url = URL(string: urlStr)!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            chulCheckResults=String(data: data, encoding: .utf8)!
        }
        task.resume()
        print(chulCheckResults)
        
        //저장된 비콘 리스트 초기화.. 여러번 시도하면 배열에 계속 쌓임
        self.beaconData=[]
        self.beaconCheckedMajorMinor=""
    }
        
    /****************웹뷰 관련 메쏘드********************/
    
    func getCookieInfo(cookieName: String) -> String {
        
        let cookieStorage = HTTPCookieStorage.shared
        let cookies = cookieStorage.cookies
        var cookieValue=""
        
        for cookie in cookies! {
            if (cookie.name==cookieName) {
                cookieValue=String(cookie.value)
            }
        }
        return cookieValue
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let schemeStr=navigationAction.request.url
        print(schemeStr!)
        
        //외부 링크 사파리로 열기!
        if let newURL = navigationAction.request.url,
            let host = newURL.host , !host.hasPrefix("app.poscohrd.com") {
            decisionHandler(.cancel)
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(newURL, options: [:])
            } else {
                UIApplication.shared.openURL(newURL)
            }
        } else {
            //출석체크 메뉴로 들어갔을 때
            if (schemeStr?.absoluteString == "http://app.poscohrd.com:8000/?ca=chul&chulSign=1#chulStart") {
               locationManager = CLLocationManager()
               locationManager.delegate = self
               locationManager.requestWhenInUseAuthorization() //권한 요청
                               
               print("checking...")
               
               //비콘 정보 받아오기
               let c=getCookieInfo(cookieName: "c")
               let i=getCookieInfo(cookieName: "i")
               let selectedCuriNo=getCookieInfo(cookieName: "selectedCuriNo")
               let selectedChaNo=getCookieInfo(cookieName: "selectedChaNo")

               guard let url = URL(string: "http://app.poscohrd.com:8000/?ca=getBeaconList&c="+c+"&i="+i+"&selectedCuriNo="+selectedCuriNo+"&selectedChaNo="+selectedChaNo) else { return }
               let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
               guard let dataResponse = data,
                         error == nil else {
                         print(error?.localizedDescription ?? "Response Error")
                         return }
                   do {
                       let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: []) as? [String: Any]
                       let beaconData=jsonResponse?["beaconInfo"] as! [Any]
                       
                       for item in beaconData {
                           var thisDic=[String:String]()
                           for (key, value) in item as! [String : Any] {
                               thisDic.updateValue(value as! String, forKey: key)
                           }
                           self.beaconData.append(thisDic)
                       }
                       self.startScanning()
                    } catch let parsingError {
                       print("Error", parsingError)
                  }
               }
               task.resume()
                //self.showAlert(vc: self, title: "출석체크 불가", message: "iOS 버전이 낮아 출석체크 기능을 사용할 수 없습니다. OS업데이트를 한 후 시도해 주세요.", actionTitle: "확인", actionStyle: .default)
            }
            decisionHandler(.allow)
        }
    }
    
    //iOS 경고창
    func showAlert(vc: UIViewController, title: String, message: String, actionTitle: String, actionStyle: UIAlertAction.Style) {
        // Create a UIAlertController.
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // Create an action of OK.
        let action = UIAlertAction(title: actionTitle, style: actionStyle) { action in print("Action OK!!") }
        // Add an Action of OK.
        alert.addAction(action)
        // Activate UIAlert.
        vc.present(alert, animated: true, completion: nil)
    }

    //alert 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    //confirm 처리
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    //confirm 처리2
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    // href="_blank" 처리
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // 중복적으로 리로드 방지
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("terminated")
        webView.reload()
    }
}
extension UIApplication {
    var statusBarView: UIView? { return value(forKey: "statusBar") as? UIView }
}
