// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.1"),
        .package(name: "google_sign_in_ios", path: "../.packages/google_sign_in_ios-6.3.0"),
        .package(name: "firebase_storage", path: "../.packages/firebase_storage-13.3.0"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.7.0"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.4.0"),
        .package(name: "firebase_app_check", path: "../.packages/firebase_app_check-0.4.3"),
        .package(name: "firebase_analytics", path: "../.packages/firebase_analytics-12.3.0"),
        .package(name: "file_picker", path: "../.packages/file_picker-10.3.10"),
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore-6.3.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "google-sign-in-ios", package: "google_sign_in_ios"),
                .product(name: "firebase-storage", package: "firebase_storage"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-app-check", package: "firebase_app_check"),
                .product(name: "firebase-analytics", package: "firebase_analytics"),
                .product(name: "file-picker", package: "file_picker"),
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
