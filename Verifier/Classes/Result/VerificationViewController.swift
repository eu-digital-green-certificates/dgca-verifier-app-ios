//
//  ResultViewController.swift
//  dgp-whitelabel-ios
//
//

import UIKit

protocol VerificationCoordinator: Coordinator {
    func dismissVerification()
}

class VerificationViewController: UIViewController {
    
    private weak var coordinator: VerificationCoordinator?
    private var viewModel: VerificationViewModel
    
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var rescanButton: UIButton!
    
    @IBOutlet weak var contentStackView: UIStackView!
    
    // MARK: - Init
    
    init(coordinator: VerificationCoordinator, viewModel: VerificationViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        
        super.init(nibName: "VerificationViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultImageView.image = UIImage(named: viewModel.imageName)
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        rescanButton.setTitle(viewModel.rescanButtonTitle, for: .normal)
        
        viewModel.resultItems?.forEach {
            if let resultView = Bundle.main.loadNibNamed("ResultView", owner: nil, options: nil)?.first as? ResultView {
                resultView.configure(with: $0)
                contentStackView.addArrangedSubview(resultView)
            }
        }
    }
    
    @IBAction func dismiss(_ sender: Any) {
        coordinator?.dismissVerification()
    }
}
