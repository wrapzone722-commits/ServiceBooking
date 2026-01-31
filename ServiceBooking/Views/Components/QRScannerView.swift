//
//  QRScannerView.swift
//  ServiceBooking
//
//  Сканер QR-кода для подключения к веб-консоли
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Binding var isPresented: Bool
    let onScan: (String) -> Void
    var onManualEntry: (() -> Void)?
    
    @State private var scannedCode: String?
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            QRScannerRepresentable(
                onCodeScanned: { code in
                    scannedCode = code
                },
                onError: { error in
                    errorMessage = error
                }
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 24) {
                    Text("Наведите камеру на QR-код\nвеб-консоли")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    ZStack {
                        ScanFrameView(size: 260)
                        ScanningLineView()
                            .frame(width: 236, height: 260)
                    }
                    .frame(width: 260, height: 260)
                    
                    Text("QR-код находится в настройках\nвеб-консоли администратора")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    if let onManualEntry = onManualEntry {
                        Button {
                            onManualEntry()
                        } label: {
                            Label("Ввести URL вручную", systemImage: "keyboard")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                }
                .padding(32)
                
                Spacer()
            }
            
            if !errorMessage.isEmpty {
                VStack {
                    HStack {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            errorMessage = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                    .padding()
                    Spacer()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                    .padding()
                }
                Spacer()
            }
            .allowsHitTesting(true)
        }
        .onChange(of: scannedCode) { _, code in
            guard let code = code, !code.isEmpty else { return }
            onScan(code)
            isPresented = false
        }
    }
}

// MARK: - Рамка сканера с углами

private struct ScanFrameView: View {
    let size: CGFloat
    private let cornerLength: CGFloat = 24
    private let cornerWidth: CGFloat = 4
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: size, height: size)
            
            // Углы рамки
            ScanCorner(edge: .topLeading, length: cornerLength, width: cornerWidth)
            ScanCorner(edge: .topTrailing, length: cornerLength, width: cornerWidth)
                .frame(width: size, height: size, alignment: .topTrailing)
            ScanCorner(edge: .bottomLeading, length: cornerLength, width: cornerWidth)
                .frame(width: size, height: size, alignment: .bottomLeading)
            ScanCorner(edge: .bottomTrailing, length: cornerLength, width: cornerWidth)
                .frame(width: size, height: size, alignment: .bottomTrailing)
        }
        .frame(width: size, height: size)
    }
}

private struct ScanCorner: View {
    enum Edge { case topLeading, topTrailing, bottomLeading, bottomTrailing }
    let edge: Edge
    let length: CGFloat
    let width: CGFloat
    
    var body: some View {
        Path { path in
            switch edge {
            case .topLeading:
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
            case .topTrailing:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
                path.addLine(to: CGPoint(x: length, y: length))
            case .bottomLeading:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: length, y: length))
            case .bottomTrailing:
                path.move(to: CGPoint(x: length, y: 0))
                path.addLine(to: CGPoint(x: length, y: length))
                path.addLine(to: CGPoint(x: 0, y: length))
            }
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        .frame(width: length, height: length)
    }
}

// MARK: - Анимация сканирующей линии

private struct ScanningLineView: View {
    @State private var offset: CGFloat = -120
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .white, .white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 4)
            
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(height: 2)
        }
        .shadow(color: .white.opacity(0.5), radius: 4)
        .offset(y: offset)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                offset = 120
            }
        }
    }
}

// MARK: - Camera Preview + QR Scanning

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    let onError: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onCodeScanned = onCodeScanned
        vc.onError = onError
        return vc
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func startScanning() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.onError?("Нет доступа к камере. Разрешите в Настройках.")
                    }
                }
            }
            return
        }
        setupSession()
    }
    
    private func setupSession() {
        let session = AVCaptureSession()
        captureSession = session
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            onError?("Камера недоступна")
            return
        }
        
        session.beginConfiguration()
        session.addInput(input)
        
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        
        output.metadataObjectTypes = [.qr]
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // Ориентация для корректного сканирования
        if let connection = output.connection(with: .metadata) {
            if #available(iOS 17.0, *) {
                connection.videoRotationAngle = 90
            } else {
                connection.videoOrientation = .portrait
            }
        }
        
        session.commitConfiguration()
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspectFill
        if let conn = layer.connection {
            if #available(iOS 17.0, *) {
                conn.videoRotationAngle = 90
            } else {
                conn.videoOrientation = .portrait
            }
        }
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let string = object.stringValue, !string.isEmpty else { return }
        
        captureSession?.stopRunning()
        onCodeScanned?(string)
    }
}
