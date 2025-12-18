# Mahina

A SwiftUI lunar calendar app that tracks Hawaiian moon phases and provides traditional planting and fishing guidance.

## Overview

Mahina displays the current lunar phase based on Hawaiian moon calendar traditions, providing:

- Daily lunar phase visualization with traditional Hawaiian names
- Planting guidance for each moon phase
- Fishing recommendations based on lunar cycles
- Interactive calendar with moon phase groups (Hoʻonui, Poepoe, Emi)
- Apple Watch companion app
- Widget support for quick phase checking

## Features

### Main App
- **Daily View**: Scroll through days with detailed lunar phase information
- **Phase Groups**: Visual representation of the three main lunar groups
- **Calendar Overlay**: Month picker for easy date navigation
- **Today Button**: Quick navigation to current date

### Apple Watch
- Companion app with essential lunar phase information
- Complications for watch faces

### Widgets
- Home screen widgets showing current lunar phase
- Quick access to phase information

## Lunar Calendar System

The app uses a continuous lunar age calculation based on a reference new moon (January 11, 2024) with a synodic month length of approximately 29.53 days. Each lunar day (1-30) corresponds to traditional Hawaiian moon names and associated activities.

### Moon Groups
- **Hoʻonui** (Days 1-10): Growth phase
- **Poepoe** (Days 11-16): Full moon period  
- **Emi** (Days 17-30): Waning phase

## Requirements

- iOS 15.0+
- watchOS 8.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone or download the project
2. Open `Mahina.xcodeproj` in Xcode
3. Build and run on your device or simulator

## Architecture

The app follows MVVM architecture with:
- **Models**: Core data structures (`MoonPhase`, `MoonDay`, `MonthData`)
- **Views**: SwiftUI views for different screens
- **Services**: Business logic (`MoonCalendarGenerator`)

## Cultural Context

This app is based on traditional Hawaiian lunar calendar knowledge. The moon phase names, planting guidance, and fishing recommendations reflect centuries of Native Hawaiian astronomical and agricultural wisdom.

## License

[Add your license information here]