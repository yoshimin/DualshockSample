//
//  ViewController.swift
//  DualshockSample
//
//  Created by Shingai Yoshimi on 2019/11/25.
//  Copyright © 2019 Shingai Yoshimi. All rights reserved.
//

import UIKit
import SceneKit
import GameController

class ViewController: UITableViewController {
    private var colors: [UIColor] = []
    private weak var pointer: UIView?
    private var displayLink: CADisplayLink?
    private var extendedGamepad: GCExtendedGamepad?
    private weak var resetAlert: UIAlertController?
    private weak var colorAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addColors()
        
        displayLink = CADisplayLink(target: self, selector: #selector(draw))
        displayLink?.add(to: .main, forMode: .default)
        
        setupNotifications()
    }
    
    @IBAction func reset() {
        colors.removeAll()
        addColors()
    }
    
    @objc private func draw() {
        guard let extendedGamepad = extendedGamepad else { return }
        let leftThumbstick = extendedGamepad.leftThumbstick
        if leftThumbstick.up.isPressed {
            scrollUp()
        }
        if leftThumbstick.down.isPressed {
            scrollDown()
        }
        
        let rightThumbstick = extendedGamepad.rightThumbstick
        movePointer(x: rightThumbstick.xAxis.value, y: rightThumbstick.yAxis.value)
    }
    
    private func addColors() {
        for _ in 1...20 {
            let color = UIColor(red: .random(in: 0...1),
                                green: .random(in: 0...1),
                                blue: .random(in: 0...1),
                                alpha: 1.0)
            colors.append(color)
        }
        tableView.reloadData()
    }
    
    private func selectColor(index: Int) {
        let color = colors[index]
        let alert = UIAlertController(title: "", message: color.hexString, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
        colorAlert = alert
    }
}

// MARK: - Table view data source
extension ViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = colors[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectColor(index: indexPath.row)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let bottomOffset = scrollView.contentSize.height - scrollView.frame.height
        if scrollView.contentOffset.y > bottomOffset {
            addColors()
        }
    }
}

// MARK: - GameController
private extension ViewController {
    func setupPointer() {
        let pointer = UIView()
        pointer.frame.size = CGSize(width: 30, height: 30)
        pointer.layer.cornerRadius = 15
        pointer.layer.borderColor = UIColor.white.cgColor
        pointer.layer.borderWidth = 1.5
        pointer.backgroundColor = UIColor(red: 0, green: 250.0/255.0, blue: 154.0/255.0, alpha: 1)
        pointer.center = tableView.center
        tableView.addSubview(pointer)
        
        self.pointer = pointer
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleControllerDidConnect),
                                               name: .GCControllerDidConnect,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleControllerDidConnect),
                                               name: .GCControllerDidDisconnect,
                                               object: nil)
    }
    
    @objc func handleControllerDidConnect(notification: Notification) {
        if let _ = pointer { return }
        
        guard let controller = notification.object as? GCController,
            let gamepad = controller.extendedGamepad else {
                return
        }
        
        setupPointer()
        
        extendedGamepad = gamepad
        
        gamepad.buttonB.pressedChangedHandler = { [weak self] (input, value, isPressed) in
            guard isPressed else { return }
            if let alert = self?.colorAlert {
                alert.dismiss(animated: true, completion: nil)
                return
            }
            if let alert = self?.resetAlert {
                self?.reset()
                alert.dismiss(animated: true, completion: nil)
                return
            }
            self?.selectCell()
        }
        gamepad.buttonA.pressedChangedHandler = { [weak self] (input, value, isPressed) in
            guard isPressed else { return }
            if let alert = self?.resetAlert {
                alert.dismiss(animated: true, completion: nil)
                return
            }
        }
        gamepad.buttonMenu.valueChangedHandler = { [weak self] (input, value, isPressed) in
            guard isPressed else { return }
            self?.showResetConfirmation()
        }
    }
    
    @objc func handleControllerDidDisconnect(notification: Notification) {
        pointer?.removeFromSuperview()
        pointer = nil
    }
    
    func selectCell() {
        guard let point = pointer?.center,
        let indexPath = tableView.indexPathForRow(at: point) else { return }
        selectColor(index: indexPath.row)
    }
    
    func scrollUp() {
        tableView.contentOffset.y += 5
    }
    
    func scrollDown() {
        var offset = tableView.contentOffset.y - 5
        if offset < 0 {
            offset = 0
        }
        tableView.contentOffset.y = offset
    }
    
    func movePointer(x: Float, y: Float) {
        guard let current = pointer?.center else { return }
        var new = CGPoint(x: current.x+CGFloat(x*10), y: current.y-CGFloat(y*10))
        if new.x > tableView.frame.width {
            new.x = tableView.frame.width
        }
        if new.x < 0 {
            new.x = 0
        }
        if new.y >= tableView.contentSize.height {
            new.y = tableView.contentSize.height
        }
        if new.y < 0 {
            new.y = 0
        }
        pointer?.center = new
    }
    
    func showResetConfirmation() {
        let alert = UIAlertController(title: "Notice", message: "Are you sure you want to reset?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.reset()
        }
        alert.addAction(ok)
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
        resetAlert = alert
    }
}


extension UIColor {
    var hexString: String? {
        guard let components = cgColor.components else { return nil }
        let r = components[0] * 255
        let g = components[1] * 255
        let b = components[2] * 255
        return String(format: "#%02X%02X%02X", Int(r), Int(g), Int(b))
    }
}
