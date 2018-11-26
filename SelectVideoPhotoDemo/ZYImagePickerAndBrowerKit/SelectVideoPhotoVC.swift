//
//  SelectVideoPhotoVC.swift
//  SelectVideoPhotoDemo
//
//  Created by 艺教星 on 2018/11/26.
//  Copyright © 2018 艺教星. All rights reserved.
//

import UIKit

class SelectVideoPhotoVC: UIViewController,ZYPhotoAlbumProtocol {
    
    var imagePickerView: ZYImagePickerLayoutView = ZYImagePickerLayoutView()
    
    override func viewDidLoad() {
        super.viewDidLoad();self.view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view.
        let photoAlbumVC = ZYPhotoNavigationViewController.init(photoAlbumDelegate: self, photoAlbumType: .selectPhoto);
        let videoAlbumVC = ZYVideoNavigationViewController(photoAlbumDelegate: self);
        //初始化需要设置代理对象
        let segView = VideoPhotoSegmentView(frame: CGRect.init(x: 0, y: 30, width: ZYScreenWidth, height: 44+44));
        self.view.addSubview(segView);
        
        
        photoAlbumVC.maxSelectCount = 9   //最大可选择张数
        //self.navigationController?.present(photoAlbumVC, animated: true, completion: nil)
        self.view.addSubview(photoAlbumVC.view)
        self.addChild(photoAlbumVC)
        photoAlbumVC.view.frame = CGRect.init(x: 0, y: 64+44, width: ZYScreenWidth, height: ZYScreenHeight-64-44)
        
        
        segView.segClosure = {(btn:UIButton) in
            
            if btn.tag == 100 {//照片
                videoAlbumVC.removeFromParent()
                videoAlbumVC.view.removeFromSuperview()
                //(photoAlbumDelegate: self)    //初始化需要设置代理对象
                photoAlbumVC.maxSelectCount = 9   //最大可选择张数
                self.view.addSubview(photoAlbumVC.view)
                self.addChild(photoAlbumVC)
                photoAlbumVC.view.frame = CGRect.init(x: 0, y: 64+44, width: ZYScreenWidth, height: ZYScreenHeight-64-44)
            }
            
            if btn.tag == 101 {//视频
                photoAlbumVC.removeFromParent()
                photoAlbumVC.view.removeFromSuperview()
                videoAlbumVC.maxSelectCount = 9   //最大可选择张数
                self.view.addSubview(videoAlbumVC.view)
                self.addChild(videoAlbumVC)
                videoAlbumVC.view.frame = CGRect.init(x: 0, y: 64+44, width: ZYScreenWidth, height: ZYScreenHeight-64-44)
            }
            
            if btn.tag == 102 {//关闭
                self.dismiss(animated: true, completion: {
                    
                });
            }
            
            if btn.tag == 103 {//完成
                //如果是照片是选中状态，则处理照片选中； 如果是视频时选中状态，则处理视频.
                if segView.photoBtnSel.isSelected{
                    if (photoAlbumVC.photoAlbumVC.rightClicked != nil){
                        photoAlbumVC.photoAlbumVC.rightClicked!();
                    }
                }
                if segView.videoBtnSel.isSelected{
                    if (videoAlbumVC.videoAlbumVC.rightClicked != nil){
                        videoAlbumVC.videoAlbumVC.rightClicked!();
                    }
                }
            }
            
        };
    }
    
    func photoAlbum(selectPhotos: [ZYPhotoModel]) {
        imagePickerView.dataSource = selectPhotos
        imagePickerView.numberOfLine = 4
        imagePickerView.reloadView()
        imagePickerView.addCallBack = {() in
            
            
        }
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}



typealias BtnClosure = ((_ btn:UIButton)->Void)

class VideoPhotoSegmentView: UIView {
    
    var segClosure:BtnClosure! = nil
    var preBtn: UIButton! = nil
    
    var photoBtnSel : UIButton! = nil
    var videoBtnSel : UIButton! = nil
    
    
    @objc func closeBtnAction(btn:UIButton){//关闭按钮
        if self.segClosure != nil {
            self.segClosure(btn)
        }
    }
    
    @objc func finishBtnAction(btn:UIButton){//完成按钮
        if self.segClosure != nil {
            self.segClosure(btn)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);self.backgroundColor = UIColor.lightGray;
        
        let closeBtn = UIButton(type: .custom)
        self.addSubview(closeBtn)
        closeBtn.addTarget(self, action: #selector(VideoPhotoSegmentView.closeBtnAction(btn:)), for: .touchUpInside)
        closeBtn.setTitle("X", for: .normal)
        closeBtn.frame = CGRect.init(x: 0, y: 0, width: 80, height: 40)
        closeBtn.tag = 100+2;
        
        let finishBtn = UIButton.init(type: .custom)
        self.addSubview(finishBtn)
        finishBtn.addTarget(self, action: #selector(VideoPhotoSegmentView.finishBtnAction(btn:)), for: .touchUpInside)
        finishBtn.setTitle("完成", for: .normal)
        finishBtn.frame = CGRect.init(x: ZYScreenWidth-80, y: 0, width: 80, height: 40)
        finishBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        finishBtn.tag = 100+3;
        
        let btn0 = UIButton(type: .custom)
        self.addSubview(btn0);btn0.setTitle("照片", for: .normal);
        btn0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn0.backgroundColor = UIColor.white
        btn0.setTitleColor(UIColor.gray, for: .normal)
        btn0.setTitleColor(UIColor.black, for: .selected)
        btn0.isSelected = true;self.preBtn = btn0;
        self.photoBtnSel = btn0;
        
        
        let btn1 = UIButton(type: .custom)
        self.addSubview(btn1);btn1.setTitle("视频", for: .normal);
        btn1.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn1.backgroundColor = UIColor.white
        btn1.setTitleColor(UIColor.gray, for: .normal)
        btn1.setTitleColor(UIColor.black, for: .selected)
        self.videoBtnSel = btn1;
        
        btn0.addTarget(self, action: #selector(VideoPhotoSegmentView.videoPhotoSegmentAction(_:)), for: .touchUpInside);
        btn1.addTarget(self, action: #selector(VideoPhotoSegmentView.videoPhotoSegmentAction(_:)), for: .touchUpInside);
        btn0.tag = 100+0;btn1.tag = 100+1;
        
        btn0.frame = CGRect.init(x: 0, y: 40, width: ZYScreenWidth/2.0-0.5, height: 40)
        btn1.frame = CGRect.init(x: ZYScreenWidth/2.0+0.5, y: 40, width: ZYScreenWidth/2.0, height: 40)
    }
    
    @objc func videoPhotoSegmentAction(_ btn:UIButton){
        if preBtn == btn {return;}
        btn.isSelected = true;
        self.preBtn.isSelected = false
        self.preBtn = btn;
        
        if btn.tag == 100 {//照片
            if self.segClosure != nil{
                self.segClosure(btn)
            }
        }
        if btn.tag == 101 {//视频
            if self.segClosure != nil{
                self.segClosure(btn)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

