//
//  ContentView.swift
//  2016 Effect
//
//  Created by Mark Mauro on 4/28/26.
//

import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = EditorViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    private let hasCamera = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                progressHeader
                photoPreview
                stepContent
            }
            .padding()
            .navigationTitle("2016 Effect")
            .sheet(isPresented: $showCamera) {
                if hasCamera {
                    CameraPicker { image in
                        if let image {
                            viewModel.trackCaptureUsed()
                            viewModel.setImage(image)
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Camera Unavailable",
                        systemImage: "camera.fill",
                        description: Text("Run on a physical device to capture photos.")
                    )
                }
            }
            .task(id: pickerItem) {
                guard let pickerItem else { return }
                if let data = try? await pickerItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.trackImportUsed()
                    viewModel.setImage(image)
                }
                self.pickerItem = nil
            }
            .alert("Saved", isPresented: $viewModel.showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Edited photo was saved to your library.")
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private var photoPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))

            if let image = viewModel.displayImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 42))
                        .foregroundStyle(.secondary)
                    Text("Capture or import a photo")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
    }

    private var progressHeader: some View {
        HStack(spacing: 8) {
            ForEach(PostingStep.allCases, id: \.rawValue) { step in
                Button(step.title) {
                    if step == .select || viewModel.hasPhoto {
                        viewModel.moveToStep(step)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(step == viewModel.currentStep ? .blue : .gray.opacity(0.4))
            }
        }
        .font(.caption.weight(.semibold))
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .select:
            selectControls
        case .filter:
            filterControls
        case .adjust:
            adjustControls
        case .export:
            exportControls
        }
    }

    private var selectControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Take Photo") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasCamera)

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text("Import Photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button("Next: Filter") {
                viewModel.advanceFromSelect()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.hasPhoto)
        }
    }

    private var filterControls: some View {
        VStack(spacing: 12) {
            TabView(selection: Binding(
                get: { viewModel.selectedPreset.id },
                set: { newID in
                    guard let preset = viewModel.presets.first(where: { $0.id == newID }) else { return }
                    viewModel.selectPreset(preset)
                }
            )) {
                ForEach(viewModel.presets) { preset in
                    filterCard(preset: preset)
                        .tag(preset.id)
                }
            }
            .frame(height: 88)
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.presets) { preset in
                        Button {
                            viewModel.selectPreset(preset)
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(viewModel.selectedPreset.id == preset.id ? Color.blue : Color.gray.opacity(0.35))
                                    .frame(width: 12, height: 12)
                                Text(preset.name)
                                    .font(.caption2)
                            }
                            .frame(minWidth: 74)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack {
                Button("Back") {
                    viewModel.moveToStep(.select)
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Next: Adjust") {
                    viewModel.advanceFromFilter()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasPhoto)
            }
        }
    }

    private func filterCard(preset: PhotoPreset) -> some View {
        VStack(spacing: 6) {
            Text(preset.name)
                .font(.subheadline.weight(.semibold))
            Text("Swipe to browse filters")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 8)
    }

    private var adjustControls: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Intensity")
                Spacer()
                Text("\(Int(viewModel.intensity * 100))%")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $viewModel.intensity, in: 0 ... 1)

            Toggle("Hold Original", isOn: $viewModel.showOriginal)
                .toggleStyle(.button)

            HStack {
                Button("Back") {
                    viewModel.moveToStep(.filter)
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Next: Export") {
                    viewModel.advanceFromAdjust()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasPhoto)
            }
        }
    }

    private var exportControls: some View {
        VStack(spacing: 12) {
            Text("Preset: \(viewModel.selectedPreset.name)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Save to Photos") {
                Task {
                    await viewModel.saveEditedPhoto()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSave)

            Button("Back to Adjust") {
                viewModel.moveToStep(.adjust)
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ContentView()
}
