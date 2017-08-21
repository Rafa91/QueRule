//
//  AddGameViewController.swift
//  queRule
//
//  Created by Rafael Navarro on 24/3/17.
//  Copyright © 2017 Rafael Navarro. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

protocol AddGameViewControllerDelegate {
    func didAddGame()
}

class AddGameViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var gameImageView : UIImageView!
    @IBOutlet weak var borrowedSwitch : UISwitch!
    @IBOutlet weak var txtTitle : UITextField!
    @IBOutlet weak var txtBorrowedTo : UITextField!
    @IBOutlet weak var txtBorrowedDate : UITextField!
    @IBOutlet weak var btnDelete : UIButton!
    
    var managedObjectContext : NSManagedObjectContext? = nil
    
    var imagePickerController = UIImagePickerController()
    var cameraPermissions : Bool = false
    
    var delegate : AddGameViewControllerDelegate?
    
    var game : Game? = nil
    
    var datePicker : UIDatePicker!
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        
        let takePictureGesture = UITapGestureRecognizer(target: self, action: #selector(takePictureTapped))
        self.gameImageView.addGestureRecognizer(takePictureGesture)
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        datePicker = UIDatePicker(frame: CGRect(x: 0, y: 210, width: 320, height: 216))
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(datePickerChangeValue), for: .valueChanged)
        txtBorrowedDate.inputView = datePicker
        
        if game == nil{
            
            self.title = "Añadir Juego"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
            
            self.btnDelete.isHidden = true
            borrowedSwitch.isOn = false
            
        }else{
            
            self.title = "Detalles"
            self.txtTitle.text = game?.title
            if let borrowed = game?.borrowed{
                self.borrowedSwitch.isOn = borrowed
            }
            self.txtBorrowedTo.text = game?.borrowedTo
            if let borrowedDate = game?.borrowedDate as? Date{
                self.txtBorrowedDate.text = dateFormatter.string(from: borrowedDate)
            }
            if let imageData = game?.image as? Data{
                self.gameImageView.image = UIImage(data: imageData)
            }
            self.btnDelete.isHidden = false
            
        }
        
        if !borrowedSwitch.isOn{
            txtBorrowedTo.isEnabled = false
            txtBorrowedDate.isEnabled = false
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool){
        super.viewWillDisappear(animated)
        if game != nil {
            saveGame()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPermissions()
    }

    
    func keyboardWillShow(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardFrame : CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        UIView.animate(withDuration: keyboardTime) { 
            self.view.frame.origin.y = -(keyboardFrame.height)
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = 0
        }
        
    }
    
    func viewTapped(){
        
        for view in self.view.subviews{
            if let textField = view as? UITextField{
                textField.resignFirstResponder()
            }
        }
        
    }
    
    func checkPermissions(){
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorisationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        switch cameraAuthorisationStatus {
        case .authorized:
            cameraPermissions = true
        case .restricted:
            cameraPermissions = false
        case .denied:
            cameraPermissions = false
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType, completionHandler: { granted in
                self.cameraPermissions = granted
            })
        }
    }
    
    func takePictureTapped(){
        
        guard cameraPermissions else{
            let permissionAlertController = UIAlertController(title: "Permisos", message: "No tiene permisos para acceder a la camara del dispositivo. Puede cambiar esta información en la app de Ajustes de iOS", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
            permissionAlertController.addAction(okAction)
            
            present(permissionAlertController, animated: true, completion: nil)
            return
        }
        
        let alertController = UIAlertController(title: "Añadir fotos del videojuego", message: "", preferredStyle: .actionSheet)
        let cameraOption = UIAlertAction(title: "Cámara", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .camera
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        let cameraRollOption = UIAlertAction(title: "Carrete", style: .default) { (alertAction) in
            self.imagePickerController.sourceType = .photoLibrary
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
        let cancelOption = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        if UIImagePickerController.isCameraDeviceAvailable(.rear){
            alertController.addAction(cameraOption)
        }
        
        alertController.addAction(cameraRollOption)
        alertController.addAction(cancelOption)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    func datePickerChangeValue(picker: UIDatePicker){
        
        self.txtBorrowedDate.text = self.dateFormatter.string(from: picker.date)
        
    }
    
    func cancelButtonPressed(){
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func saveButtonPressed(){
        
        saveGame()
        dismiss(animated: true, completion: nil)
        
    }
    
    func saveGame(){
        
        if let context = self.managedObjectContext{
            
            var editedGame : Game? = nil
            if game == nil{
                editedGame = Game(context: context)
            }else{
                editedGame = game
            }
            
            if let editedGame = editedGame{
                editedGame.dateCreated = NSDate()
                if let title = txtTitle.text{
                    editedGame.title = title
                }
                editedGame.borrowed = borrowedSwitch.isOn
                if let image =  gameImageView.image{
                    editedGame.image = UIImagePNGRepresentation(image) as NSData?
                }else{
                    editedGame.image  = NSData()
                }
                
                if editedGame.borrowed{
                    if let borrowedTo = txtBorrowedTo.text{
                        editedGame.borrowedTo = borrowedTo.uppercased()
                    }
                    if let strDate = txtBorrowedDate.text {
                        editedGame.borrowedDate = dateFormatter.date(from: strDate) as NSDate?
                    }
                }else{
                    editedGame.borrowedTo = nil
                    editedGame.borrowedDate = nil
                }
                
                do{
                    try context.save()
                    self.delegate?.didAddGame()
                } catch{
                    print("ha habido un error al guardar los datos en core data")
                }
                
            }
            
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickerImage = info[UIImagePickerControllerEditedImage] as? UIImage{
            self.gameImageView.image = pickerImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        
        if sender.isOn{
            txtBorrowedTo.isEnabled = true
            txtBorrowedDate.isEnabled = true
            txtBorrowedDate.text = dateFormatter.string(from: Date())
        }else{
            txtBorrowedTo.text = ""
            txtBorrowedDate.text = ""
            txtBorrowedTo.isEnabled = false
            txtBorrowedDate.isEnabled = false
        }
        
    }
    

    @IBAction func deletePressed(_ sender: UIButton) {
        
        if let context = self.managedObjectContext{
            context.delete(game!)
            game = nil
            delegate?.didAddGame()
            let _ = navigationController?.popViewController(animated: true)
        }
        
    }

}
