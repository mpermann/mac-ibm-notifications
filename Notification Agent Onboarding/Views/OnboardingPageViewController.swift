//
//  OnboardingPageViewController.swift
//  Notification Agent
//
//  Created by Simone Martorelli on 21/01/2021.
//  Copyright © 2021 IBM Inc. All rights reserved.
//  SPDX-License-Identifier: Apache2.0
//

import Cocoa

final class OnboardingPageViewController: NSViewController {

    // MARK: - Enums

    /// The position of the page in the onboarding process.
    enum PagePosition {
        case first
        case last
        case middle
        case singlePage
        var rightButtonTitle: String {
            switch self {
            case .first:
                return "onboarding_page_continue_button".localized
            case .middle:
                return "onboarding_page_continue_button".localized
            case .last, .singlePage:
                return "onboarding_page_close_button".localized
            }
        }
        var leftButtonTitle: String {
            return "onboarding_page_back_button".localized
        }
        var isRightButtonHidden: Bool {
            switch self {
            case .first, .middle, .last, .singlePage:
                return false
            }
        }
        var isLeftButtonHidden: Bool {
            switch self {
            case .first, .singlePage:
                return true
            case .middle, .last:
                return false
            }
        }
    }

    // MARK: - Outlets

    @IBOutlet weak var topIconImageView: NSImageView!
    @IBOutlet weak var bodyStackView: NSStackView!
    @IBOutlet weak var rightButton: NSButton!
    @IBOutlet weak var leftButton: NSButton!
    @IBOutlet weak var helpButton: NSButton!

    // MARK: - Variables

    weak var navigationDelegate: OnboardingNavigationDelegate?
    var titleLabel: NSTextField!
    var subtitleLabel: NSTextField!
    var bodyTextView: MarkdownTextView!
    var mediaView: NSView!
    let page: OnboardingPage
    let position: PagePosition

    // MARK: - Initializers

    init(with page: OnboardingPage, position: PagePosition) {
        self.page = page
        self.position = position
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Instance methods
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.setupStackViewLayout()
        self.setupButtonsLayout()
        self.configureAccessibilityElements()
        self.setIconIfNeeded()
    }

    // MARK: - Private methods

    /// Set up the stackview components and layout.
    private func setupStackViewLayout() {
        self.bodyStackView.distribution = .gravityAreas
        self.bodyStackView.alignment = .centerX
        self.bodyStackView.spacing = 12
        
        var remainingSpace = bodyStackView.bounds.height
        var topGravityAreaIndex = 0
        if let title = page.title {
            titleLabel = NSTextField(wrappingLabelWithString: title)
            titleLabel.font = NSFont.boldSystemFont(ofSize: 26)
            titleLabel.alignment = .center
            bodyStackView.insertView(titleLabel, at: topGravityAreaIndex, in: .top)
            topGravityAreaIndex += 1
            remainingSpace -= titleLabel.intrinsicContentSize.height+12
        }
        if let subtitle = page.subtitle {
            subtitleLabel = NSTextField(wrappingLabelWithString: subtitle)
            subtitleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
            subtitleLabel.alignment = .center
            bodyStackView.insertView(subtitleLabel, at: topGravityAreaIndex, in: .top)
            topGravityAreaIndex += 1
            remainingSpace -= subtitleLabel.intrinsicContentSize.height+12
        }
        if let pageMedia = page.pageMedia {
            if let body = page.body {
                bodyTextView = MarkdownTextView(withText: body, maxViewHeight: remainingSpace, alignment: .center)
                bodyStackView.insertView(bodyTextView, at: 0, in: .center)
                remainingSpace -= bodyTextView.fittingSize.height+12
            }
            switch pageMedia.mediaType {
            case .image:
                guard pageMedia.image  != nil else { return }
                mediaView = ImageAccessoryView(with: pageMedia, preferredSize: CGSize(width: bodyStackView.bounds.width, height: remainingSpace), needsFullWidth: false)
                bodyStackView.insertView(mediaView, at: 0, in: .bottom)
            case .video:
                guard pageMedia.player != nil else { return }
                mediaView = VideoAccessoryView(with: pageMedia, preferredSize: CGSize(width: bodyStackView.bounds.width, height: remainingSpace), needsFullWidth: false)
                bodyStackView.insertView(mediaView, at: 0, in: .bottom)
            }
        } else {
            if let body = page.body {
                bodyTextView = MarkdownTextView(withText: body, maxViewHeight: remainingSpace, alignment: .center)
                bodyStackView.insertView(bodyTextView, at: topGravityAreaIndex, in: .top)
            }
        }
    }

    /// Set up buttons appearence.
    private func setupButtonsLayout() {
        rightButton.isHidden = position.isRightButtonHidden
        leftButton.isHidden = position.isLeftButtonHidden
        rightButton.title = position.rightButtonTitle
        leftButton.title = position.leftButtonTitle
        helpButton.isHidden = !(page.infoSection != nil)
    }
    
    /// This method load and set the icon if a custom one was defined.
    private func setIconIfNeeded() {
        if let iconPath = page.topIcon,
           FileManager.default.fileExists(atPath: iconPath) {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: iconPath)),
               let image = NSImage(data: data) {
                topIconImageView.image = image
            }
        } else {
            topIconImageView.image = NSImage(named: NSImage.Name("default_icon"))
        }
    }

    private func goToNextPage() {
        self.navigationDelegate?.didSelectNextButton(self)
    }

    private func goToPreviousPage() {
        self.navigationDelegate?.didSelectBackButton(self)
    }

    /// Exit the completed onboarding.
    private func closeOnboarding() {
        EFCLController.shared.applicationExit(withReason: .userFinishedOnboarding)
    }
    
    private func configureAccessibilityElements() {
        self.rightButton.setAccessibilityLabel(position == .last ? "onboarding_accessibility_button_right_close".localized : "onboarding_accessibility_button_right_continue".localized)
        self.leftButton.setAccessibilityLabel("onboarding_accessibility_button_left".localized)
        self.helpButton.setAccessibilityLabel("onboarding_accessibility_button_center".localized)
        self.bodyStackView.setAccessibilityLabel("onboarding_accessibility_stackview_body".localized)
        self.topIconImageView.setAccessibilityLabel("onboarding_accessibility_image_top".localized)
    }

    // MARK: - Actions

    @IBAction func didPressRightButton(_ sender: NSButton) {
        switch position {
        case .first:
            goToNextPage()
        case .middle:
            goToNextPage()
        case .last, .singlePage:
            closeOnboarding()
        }
    }

    @IBAction func didPressLeftButton(_ sender: NSButton) {
        switch position {
        case .first, .singlePage:
            return
        case .middle:
            goToPreviousPage()
        case .last:
            goToPreviousPage()
        }
    }

    @IBAction func didPressHelpButton(_ sender: NSButton) {
        guard let infos = page.infoSection else { return }
        let infoPopupViewController = InfoPopOverViewController(with: infos)
        self.present(infoPopupViewController,
                     asPopoverRelativeTo: sender.convert(sender.bounds, to: self.view),
                     of: self.view,
                     preferredEdge: .maxX,
                     behavior: .semitransient)
    }
}
