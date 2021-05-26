//
//  HomeViewModel.swift
//  verifier-ios
//
//

import Foundation

class HomeViewModel {
            
    var lastUpdateText: Observable<String> = Observable("home.loading".localized)
    var isLoading: Observable<Bool> = Observable(true)
    var isScanEnabled: Observable<Bool> = Observable(false)
    var isVersionOutdated: Observable<Bool> = Observable(true)
    
    private func updateLastUpdateDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy, HH:mm"
        lastUpdateText.value = "home.lastUpdate".localized + dateFormatter.string(from: LocalData.sharedInstance.lastFetch)
    }
    
    func loadCertificates() {
        LocalData.initialize { [weak self] in
            if LocalData.sharedInstance.lastFetch.timeIntervalSince1970 != 0 {
                self?.updateLastUpdateDate()
                self?.isScanEnabled.value = true
            }
            GatewayConnection.initialize { [weak self] error, isVersionOutdated in
                self?.isLoading.value = false
                
                if error != nil {
                    self?.lastUpdateText.value = error
                    return
                }
                
                self?.updateLastUpdateDate()
                
                self?.isScanEnabled.value = true
                self?.isVersionOutdated.value = isVersionOutdated
            }
        }
    }
}
