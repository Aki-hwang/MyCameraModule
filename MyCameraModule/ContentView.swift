//
//  ContentView.swift
//  MyCameraModule
//
//  Created by Chuljin Hwang on 2022/02/06.
//

import SwiftUI
import AVFoundation // 카메라 모듈을 사용위해

struct ContentView: View {
   @StateObject var camera = CameraModel()
    //클래스로 정의하고 인스턴스 생성해주면 이런식으로 사용할수 있구나.
    var body: some View {
        ZStack{
            CameraPreview(camera: camera)
                .edgesIgnoringSafeArea(.all)

            VStack {
                if camera.isTaken{
                    HStack {
                        Spacer()
                        Button(action: {
                            camera.retake()
                        }, label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                                .padding(.trailing, 30)
                        })

                    }
                    Spacer()
                    Button(action: {
                        if !camera.isSaved{
                            camera.savePic()
                        }
                    }, label: {
                        ZStack{
                            Text(camera.isSaved ? "Saved" : "Save")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .padding(.bottom, 20)
                            }
                    })
                }else{

                    Spacer()
                    Button(action: {
                        camera.takePic()
                    }, label: {
                        ZStack{
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 3)
                                .frame(width: 75, height: 75)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                                
                            }
                    })
                }
            }
        } // zstack
        .onAppear(perform: {
            camera.CheckAuthor()
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


class CameraModel : NSObject, ObservableObject, AVCapturePhotoCaptureDelegate{
    
    //사진 찍기 위해NSObject,AVCapturePhotoCaptureDelegate 프로토콜 추가
    @Published var isTaken : Bool = false // 카메라 버튼을 변경 위해
    
    @Published var session = AVCaptureSession()
    
    @Published var alert : Bool = false
    
    @Published var output = AVCapturePhotoOutput()
    
    @Published var preview : AVCaptureVideoPreviewLayer!
    
    //pic data
    @Published var isSaved = false
    @Published var picData = Data(count: 0)
//===============================================================
    func CheckAuthor(){
        //이 아래 부분은 애플에서 제공하는 승인 받는 과정임
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
            // The user has previously granted access to the camera.
            setUp()
            return
            case .notDetermined:
            // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.setUp()
                    }
                }
            case .denied: // The user has previously denied access.
            self.alert.toggle()
            return
            default:
            return
//            case .restricted: // The user can't grant access due to restrictions.
        }
    }
    
    func setUp(){
        
        do{
            self.session.beginConfiguration()
            
            let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
            let input = try AVCaptureDeviceInput(device: device!)
            
            //세션 확인 및 추가
            if self.session.canAddInput(input){
                self.session.addInput(input)
            }
            if self.session.canAddOutput(self.output){
                self.session.addOutput(self.output)
            }
            self.session.commitConfiguration()
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    //setting take and retake functions

    func takePic(){ //qos : quality of service 시스템의 중요도를 설정해서 우선순위 정해
        //dispatchQueue는 작업항목의 실행을 관리하는 클래스
        //async 다른 큐에 작업을 추가하고 동시에 다른 작업을 할수 있게 진행
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            self.session.stopRunning()
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    
    func retake(){
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
                self.isSaved = false
            }
        }
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?){
        if error != nil{
            return
        }
        print("pic photo")
        guard let imageData = photo.fileDataRepresentation() else{return}
        self.picData = imageData
    }
        
    func savePic(){
        let image = UIImage(data: self.picData)!
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        self.isSaved = true
        print("save successful")
    }
  
}
//===============================================================

//setting view for preview

struct CameraPreview: UIViewRepresentable{
    @ObservedObject var camera : CameraModel
    func makeUIView(context: Context) ->   UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        //strat session
        camera.session.startRunning()
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}


