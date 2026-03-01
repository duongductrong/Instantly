# Project Overview & Product Development Requirements (PDR)

**Project Name**: Instantly
**Version**: 0.1.0
**Last Updated**: 2026-03-01
**Status**: Pre-Development
**Platform**: macOS (SwiftUI + AppKit)

## Executive Summary

Instantly is a macOS AI assistant that works across all applications on a user's device. Invoked via global hotkey, menu bar, or text selection, it provides instant AI-powered text actions (rewrite, summarize, translate, expand) with any app. Built for speed and polish, it differentiates through sub-second response UX, beautiful native design, and a modular architecture that grows with plugins over time.

**Privacy-first**: All AI calls go directly from user's device to provider. No proxy. No data collection.

## Project Purpose

### Vision
The fastest, most beautiful system-wide AI assistant for macOS — one that feels like a native OS feature, not a third-party tool.

### Mission
Build a macOS-native AI tool that:
- Works instantly across any application via hotkey, menu bar, or text selection
- Provides AI text actions (rewrite, summarize, translate, expand) with sub-second perceived latency
- Supports multiple AI providers (OpenAI, Anthropic, Google, local models)
- Maintains user privacy via direct device-to-provider communication
- Grows through a modular plugin architecture

### Value Proposition
- **Speed**: Sub-200ms UI response. Streaming AI output. Feels instant.
- **Universal**: Works in any app — browsers, editors, terminals, email clients.
- **Privacy**: Zero data passes through third-party servers. Direct API calls only.
- **Beautiful**: Native macOS design language. Feels like an Apple feature.
- **Extensible**: Plugin system for new capabilities without bloating the core.

## Target Users

### Primary Users
1. **Knowledge Workers** — writers, marketers, support agents who process text all day
2. **Developers** — need quick code explanations, documentation rewrites, commit messages
3. **Students & Researchers** — summarize papers, rephrase content, translate
4. **macOS Power Users** — already use Raycast/Alfred, want AI natively integrated

### User Persona

**Persona 1: Knowledge Worker (Primary)**
- **Needs**: Rewrite emails faster, summarize long docs, translate messages
- **Pain Points**: Copy-pasting into ChatGPT breaks flow, Apple Intelligence too limited
- **Solution**: Select text in any app → instant AI action via popover

**Persona 2: Developer**
- **Needs**: Quick explanations, code comments, documentation writing
- **Pain Points**: Context switching to AI chat tools
- **Solution**: Hotkey panel for quick queries + text selection for inline edits

**Persona 3: Power User**
- **Needs**: Customizable AI workflows, multiple providers, keyboard-driven
- **Pain Points**: Locked into one AI provider, slow/bloated tools
- **Solution**: Multi-provider support, plugin system, native speed

## Key Features & Capabilities

### MVP (v1.0)

#### 1. Global Hotkey Panel
- Customizable hotkey (default: `Cmd+Shift+Space`) opens floating AI panel
- Panel appears over current app as a translucent overlay
- Chat-style interface for quick AI queries
- Streaming response display
- Dismiss with `Esc` or clicking outside
- Panel remembers position and size

#### 2. Text Selection Actions
- Select text in any app → trigger via hotkey (e.g., `Cmd+Shift+A`)
- Small popover appears near selection with action buttons:
  - **Rewrite** — improve clarity and tone
  - **Summarize** — condense to key points
  - **Translate** — target language selection
  - **Expand** — elaborate on the content
  - **Fix Grammar** — correct errors
  - **Custom Prompt** — user-defined action
- Result replaces selection or copies to clipboard
- Action history for quick re-use

#### 3. Menu Bar Presence
- Persistent menu bar icon (always accessible)
- Dropdown shows:
  - Quick action buttons
  - Recent conversations
  - Provider status / API key health
  - Settings shortcut
- Click-to-open floating panel (alternative to hotkey)

#### 4. Multi-Provider AI Backend
- Support for:
  - OpenAI (GPT-4o, GPT-4.1)
  - Anthropic (Claude Sonnet, Opus)
  - Google (Gemini Pro, Flash)
  - Local models via Ollama/MLX (future)
- User brings own API keys (BYOK)
- Per-action provider selection (e.g., "use Claude for writing, GPT for code")
- Streaming responses for all providers
- Provider health check and fallback

#### 5. Settings & Configuration
- API key management (secure Keychain storage)
- Default provider selection
- Hotkey customization
- Appearance (auto/light/dark)
- Custom prompt templates
- Launch at login toggle

### Post-MVP (v1.x+)

- Screenshot/OCR capture → send screen context to AI
- Plugin/extension system for custom actions
- Conversation history with search
- Clipboard history integration
- Workflow automation (chain multiple AI actions)
- Local model support (MLX/Ollama)

## Technical Architecture

### Technology Stack

| Layer | Technology |
|-------|-----------|
| **UI Framework** | SwiftUI + AppKit |
| **Language** | Swift 6 |
| **Data** | SwiftData (settings, history) |
| **Networking** | URLSession + async/await (streaming SSE) |
| **Security** | Keychain Services (API keys) |
| **Accessibility** | Accessibility API (text selection detection) |
| **System Integration** | NSEvent (global hotkeys), NSStatusItem (menu bar), NSPanel (overlay) |
| **Minimum Target** | macOS 14.0 (Sonoma) |

### Project Structure (Pragmatic Flattened)

```
App/
  App.swift                        // @main entry
  AppCoordinator.swift             // Window & overlay management
  AppEnvironment.swift             // DI container

Features/
  Panel/                           // Global hotkey floating panel
    PanelView.swift
    PanelViewModel.swift
    Components/
      MessageBubble.swift
      StreamingTextView.swift

  TextActions/                     // Text selection popover
    TextActionsView.swift
    TextActionsViewModel.swift
    Components/
      ActionButton.swift
      ResultPreview.swift

  MenuBar/                         // Menu bar dropdown
    MenuBarView.swift
    MenuBarViewModel.swift

  Settings/                        // App settings
    SettingsView.swift
    SettingsViewModel.swift
    Components/
      APIKeyField.swift
      ProviderPicker.swift

Services/
  AIService/                       // Multi-provider AI abstraction
    AIService.swift                // Protocol + router
    OpenAIProvider.swift
    AnthropicProvider.swift
    GeminiProvider.swift
    StreamingParser.swift

  HotkeyService.swift              // Global hotkey registration
  AccessibilityService.swift       // Text selection detection
  KeychainService.swift            // Secure API key storage
  ClipboardService.swift           // Clipboard read/write

Shared/
  Components/                      // Reusable UI
  Extensions/                      // Swift extensions
  Models/                          // Shared data models
  Styles/                          // Design tokens

Resources/
  Assets.xcassets
  Info.plist
```

### System Interaction Flow

```
User triggers (hotkey / text selection / menu bar click)
    |
    v
AppCoordinator (routes to correct feature)
    |
    +--> PanelView (floating chat overlay)
    |        |
    |        v
    |    AIService.stream(prompt, provider)
    |        |
    |        v
    |    [OpenAI / Anthropic / Gemini] API (direct from device)
    |        |
    |        v
    |    StreamingParser --> UI update (real-time)
    |
    +--> TextActionsView (popover near selection)
    |        |
    |        v
    |    AccessibilityService.getSelectedText()
    |        |
    |        v
    |    AIService.stream(action + text, provider)
    |        |
    |        v
    |    Result --> Replace selection or copy to clipboard
    |
    +--> MenuBarView (dropdown)
             |
             v
         Quick actions / Settings / Recent history
```

## Functional Requirements

**FR1: Global Hotkey Overlay**
- Register system-wide hotkey via NSEvent.addGlobalMonitorForEvents
- Show/hide floating NSPanel above all apps
- Panel is non-activating (doesn't steal focus from current app)
- Support keyboard-driven interaction (type immediately on open)

**FR2: Text Selection Detection**
- Use macOS Accessibility API to detect selected text across apps
- Request Accessibility permission on first use
- Support fallback to clipboard-based detection

**FR3: AI Provider Abstraction**
- Common protocol for all providers (send prompt, receive stream)
- SSE/streaming parsing for real-time output
- Error handling: rate limits, auth failures, network errors
- Provider switching without restart

**FR4: Secure Key Storage**
- Store API keys in macOS Keychain (not UserDefaults)
- Validate keys on entry (test API call)
- Never log or transmit keys

**FR5: Text Replacement**
- After AI generates output, optionally replace selected text in source app
- Use Accessibility API or clipboard + Cmd+V simulation
- Undo support where possible

## Non-Functional Requirements

**NFR1: Performance**
- UI appears in <100ms after hotkey press
- First AI token streams within 500ms (network dependent)
- App memory footprint <50MB idle
- CPU usage <1% when idle

**NFR2: Privacy**
- Zero telemetry, zero analytics, zero server communication
- All AI calls are direct: device → provider API
- API keys stored in macOS Keychain only
- No conversation data leaves the device (unless to AI provider)

**NFR3: Reliability**
- Graceful handling of API failures (show error, don't crash)
- Hotkey works even when app is in background
- App survives sleep/wake cycles
- Auto-recovery from crashed state

**NFR4: Accessibility**
- VoiceOver support for panel and popover
- Keyboard-navigable UI
- Respects system accent color and appearance
- Dynamic Type support

**NFR5: macOS Integration**
- Native look and feel (no Electron)
- Respects system appearance (light/dark/auto)
- Spotlight-quality animation and blur
- Follows macOS HIG

## Competitive Analysis

| Feature | Instantly | Raycast AI | Apple Intelligence | ChatGPT Mac |
|---------|-----------|------------|-------------------|-------------|
| System-wide text actions | Yes | Partial | Yes (limited) | No |
| Multi-provider | Yes | No (OpenAI) | No (Apple) | No (OpenAI) |
| BYOK (no subscription) | Yes | No ($8/mo) | Free but limited | $20/mo |
| Native macOS feel | Yes | Yes | Yes | Electron |
| Privacy (direct calls) | Yes | No (proxied) | Yes | No |
| Plugin system | Planned | Yes | No | No |
| Speed focus | Core value | Good | Good | Slow |
| Open source potential | Possible | No | No | No |

## Success Metrics

### Performance Metrics
- Hotkey-to-panel: <100ms
- First token latency: <500ms (network dependent)
- Idle memory: <50MB
- Idle CPU: <1%

### User Experience Metrics
- Onboarding to first AI action: <2 minutes
- Daily active usage sessions: track locally
- Most-used actions: track locally for UX optimization
- Crash-free rate: >99.9%

### Adoption Metrics (if distributed)
- GitHub stars (if open source)
- Mac App Store downloads (if published)
- Community contributions (plugins, providers)

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Accessibility API permission friction | High | High | Clear onboarding guide, fallback to clipboard |
| AI provider API changes | Medium | Medium | Abstraction layer, quick provider updates |
| Apple Intelligence catches up | High | Medium | Focus on multi-provider, speed, extensibility |
| macOS sandboxing restrictions | High | Low | Research entitlements early, test on App Store |
| Text replacement fails in some apps | Medium | High | Clipboard fallback, user notification |

## Development Phases

### Phase 1: Foundation (v0.1 - v0.3)
- App shell with menu bar icon
- Global hotkey registration
- Floating panel (basic chat UI)
- Single AI provider (OpenAI) integration
- Streaming response display
- Settings view with API key management

### Phase 2: Core Features (v0.4 - v0.7)
- Text selection detection via Accessibility API
- Text action popover (rewrite, summarize, translate, expand, fix grammar)
- Multi-provider support (add Anthropic, Gemini)
- Keychain-based API key storage
- Text replacement in source apps
- Custom prompt templates

### Phase 3: Polish & Ship (v0.8 - v1.0)
- Animation and visual polish
- Error handling and edge cases
- Onboarding flow
- Performance optimization
- Accessibility (VoiceOver, keyboard nav)
- Launch at login
- Beta testing

### Phase 4: Growth (v1.x+)
- Screenshot/OCR capture
- Plugin/extension system
- Conversation history
- Local model support (MLX/Ollama)
- Workflow automation
- App Store submission

## Technical Constraints

- **macOS 14.0+** minimum (for SwiftData, modern SwiftUI)
- **Accessibility permission** required for text selection (user must grant)
- **No iOS/iPadOS** — macOS only for now
- **No server** — fully client-side, BYOK model
- **Swift 6** concurrency model (strict sendable checking)

## Glossary

- **BYOK** — Bring Your Own Key. Users provide their own AI API keys.
- **SSE** — Server-Sent Events. Streaming protocol used by AI APIs.
- **NSPanel** — macOS window type that floats above normal windows.
- **Accessibility API** — macOS API for reading UI elements across apps.
- **MLX** — Apple's machine learning framework for on-device inference.

## Unresolved Questions

1. **Monetization**: Free + BYOK vs freemium vs one-time purchase? Defer to post-MVP.
2. **App Store vs Direct**: Sandboxing may limit Accessibility API usage. Need to test.
3. **Text Replacement Reliability**: Some apps block programmatic text insertion. How to handle gracefully?
4. **Plugin Architecture**: What format? Swift packages? Scripting layer? Defer to v1.x.
5. **Local Models**: MLX vs Ollama vs llama.cpp? Defer to v1.x.
