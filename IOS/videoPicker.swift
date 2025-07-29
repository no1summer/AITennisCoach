import SwiftUI
import PhotosUI

struct VideoPicker: UIViewControllerRepresentable {
    var didFinishPicking: (URL) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                picker.dismiss(animated: true)
                return
            }
            
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                if let url = url {
                    // PHPicker gives us a temporary read-only URL.
                    // We need to copy it to our app's directory to get a stable path.
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let newURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(url.pathExtension)
                    
                    try? FileManager.default.copyItem(at: url, to: newURL)
                    
                    DispatchQueue.main.async {
                        self.parent.didFinishPicking(newURL)
                    }
                } else if let error = error {
                    print("Error loading video: \(error.localizedDescription)")
                    picker.dismiss(animated: true)
                }
            }
        }
    }
}