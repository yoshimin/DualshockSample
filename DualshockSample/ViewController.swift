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

    override func viewDidLoad() {
        super.viewDidLoad()
        addColors()

        setupNotifications()
    }

    @IBAction func reset() {
        colors.removeAll()
        addColors()
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
        let color = colors[indexPath.row]
        let alert = UIAlertController(title: "", message: color.hexString, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
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
        pointer.frame.size = CGSize.init(width: 30, height: 30)
        pointer.layer.borderColor = UIColor(red: 0, green: 250.0/255.0, blue: 154.0/255.0, alpha: 1).cgColor
        pointer.layer.borderWidth = 1.5
        pointer.backgroundColor = .red
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
        guard let controller = notification.object as? GCController,
            let gamepad = controller.extendedGamepad else {
            return
        }

        setupPointer()

        gamepad.buttonB.pressedChangedHandler = { [weak self] (input, value, isPressed) in
            self?.selectCell()
        }
        gamepad.rightThumbstick.valueChangedHandler = { [weak self] (pad, xAxis, yAxis) in
            self?.movePointer(xAxis: xAxis, yAxis: xAxis)
        }
        gamepad.buttonMenu.valueChangedHandler = { [weak self] (input, value, isPressed) in
            self?.showResetConfirmation()
        }
    }

    @objc func handleControllerDidDisconnect(notification: Notification) {
        pointer?.removeFromSuperview()
        pointer = nil
    }

    func selectCell() {
        guard let point = pointer?.center else { return }
        let indexPath = tableView.indexPathForRow(at: point)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }

    func movePointer(xAxis: Float, yAxis: Float) {
        guard let current = pointer?.center else { return }
        var new = CGPoint(x: current.x+CGFloat(xAxis)*10, y: current.y+CGFloat(yAxis)*10)
        if new.y >= tableView.frame.height {
            new.y = tableView.frame.height
            pointer?.center = new
            tableView.contentOffset.y += 5
            return
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
        alert.addAction(ok)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
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
