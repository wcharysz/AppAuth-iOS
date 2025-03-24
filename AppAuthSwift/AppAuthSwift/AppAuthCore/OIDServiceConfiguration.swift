//
//  OIDServiceConfiguration.swift
//  AppAuthSwift
//
//  Created by Charysz, Wojciech on 24.03.25.
//

import Foundation

struct OIDServiceConfiguration {
    
    ///The authorization endpoint URI.
    var authorizationEndpoint: URL
    
    /// The token exchange and refresh endpoint URI.
    var tokenEndpoint: URL
    
    /// The OpenID Connect issuer.
    var issuer: URL?
    
    /// The dynamic client registration endpoint URI.
    var registrationEndpoint: URL?
    
    /// The end session logout endpoint URI.
    var endSessionEndpoint: URL?
    
    /// The discovery document.
    var discoveryDocument: OIDServiceDiscovery?
    
    init(authorizationEndpoint: URL, tokenEndpoint: URL) {
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
    }
    
    init(authorizationEndpoint: URL, tokenEndpoint: URL, registrationEndpoint: URL?) {
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.registrationEndpoint = registrationEndpoint
    }
    
    init(authorizationEndpoint: URL, tokenEndpoint: URL, issuer: URL?) {
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.issuer = issuer
    }
    
    init(authorizationEndpoint: URL, tokenEndpoint: URL, issuer: URL?, registrationEndpoint: URL?) {
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.issuer = issuer
        self.registrationEndpoint = registrationEndpoint
    }
    
    init(authorizationEndpoint: URL, tokenEndpoint: URL, issuer: URL?, registrationEndpoint: URL?, endSessionEndpoint: URL?) {
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.issuer = issuer
        self.registrationEndpoint = registrationEndpoint
        self.endSessionEndpoint = endSessionEndpoint
    }
    
    init(discoveryDocument: OIDServiceDiscovery) {
        self.discoveryDocument = discoveryDocument
        self.authorizationEndpoint = discoveryDocument.authorizationEndpoint
        self.tokenEndpoint = discoveryDocument.tokenEndpoint
        self.issuer = discoveryDocument.issuer
        self.registrationEndpoint = discoveryDocument.registrationEndpoint
        self.endSessionEndpoint = discoveryDocument.endSessionEndpoint
    }
}
