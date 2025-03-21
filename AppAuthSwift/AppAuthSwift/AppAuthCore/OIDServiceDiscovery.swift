//
//  OIDServiceDiscovery.swift
//  AppAuthSwift
//
//  Created by Charysz, Wojciech on 20.03.25.
//
import Foundation

/// Represents an OpenID Connect 1.0 Discovery Document
/// See: https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
public struct OIDServiceDiscovery {
    
    // MARK: - Properties
    
    /// The decoded OpenID Connect 1.0 Discovery Document as a dictionary
    public let discoveryDictionary: [String: Codable]
    
    /// REQUIRED. URL using the https scheme with no query or fragment component that the OP
    /// asserts as its Issuer Identifier
    public let issuer: URL
    
    /// REQUIRED. URL of the OP's OAuth 2.0 Authorization Endpoint
    public let authorizationEndpoint: URL
    
    /// OPTIONAL. URL of the OP's OAuth 2.0 Device Authorization Endpoint
    public let deviceAuthorizationEndpoint: URL?
    
    /// URL of the OP's OAuth 2.0 Token Endpoint
    public let tokenEndpoint: URL
    
    /// RECOMMENDED. URL of the OP's UserInfo Endpoint
    public let userinfoEndpoint: URL?
    
    /// REQUIRED. URL of the OP's JSON Web Key Set document
    public let jwksURL: URL
    
    /// RECOMMENDED. URL of the OP's Dynamic Client Registration Endpoint
    public let registrationEndpoint: URL?
    
    /// OPTIONAL. URL of the OP's RP-Initiated Logout endpoint
    public let endSessionEndpoint: URL?
    
    /// RECOMMENDED. List of the OAuth 2.0 scope values that this server supports
    public let scopesSupported: [String]?
    
    /// REQUIRED. List of the OAuth 2.0 response_type values that this OP supports
    public let responseTypesSupported: [String]
    
    /// OPTIONAL. List of the OAuth 2.0 response_mode values that this OP supports
    public let responseModesSupported: [String]?
    
    /// OPTIONAL. List of the OAuth 2.0 Grant Type values that this OP supports
    public let grantTypesSupported: [String]?
    
    /// OPTIONAL. List of the Authentication Context Class References that this OP supports
    public let acrValuesSupported: [String]?
    
    /// REQUIRED. List of the Subject Identifier types that this OP supports
    public let subjectTypesSupported: [String]
    
    /// REQUIRED. List of JWS signing algorithms supported for ID Token
    public let idTokenSigningAlgorithmValuesSupported: [String]
    
    /// OPTIONAL. List of JWE encryption algorithms supported for ID Token
    public let idTokenEncryptionAlgorithmValuesSupported: [String]?
    
    /// OPTIONAL. List of JWE encryption encodings supported for ID Token
    public let idTokenEncryptionEncodingValuesSupported: [String]?
    
    // ... Additional properties follow the same pattern
    
    // MARK: - Initialization
    
    /// Creates a new ServiceDiscovery instance from JSON
    /// - Parameter json: JSON string containing the discovery document
    /// - Throws: Error if JSON is invalid or required fields are missing
    ///
    ///
    ///
    ///

    
    /*
    public init(json: String) throws {
        guard let jsonData = json.data(using: .utf8) else {
            throw ServiceDiscoveryError.invalidJSON
        }
        //try self.init(jsonData: jsonData)
    }
     */
    
    /// Creates a new ServiceDiscovery instance from JSON Data
    /// - Parameter jsonData: JSON data containing the discovery document
    /// - Throws: Error if JSON is invalid or required fields are missing
    //
    
    /*
    public init(jsonData: Data) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(OIDServiceDiscovery.self, from: jsonData)
    }
     */
    
    /// Creates a new ServiceDiscovery instance from a dictionary
    /// - Parameter dictionary: Dictionary containing the discovery document
    /// - Throws: Error if required fields are missing
    ///
    
    /*
    public init(dictionary: [String: Codable]) throws {
        // Implement validation and initialization logic
        guard Self.dictionaryHasRequiredFields(dictionary) else {
            throw ServiceDiscoveryError.missingRequiredFields
        }
        
        self.discoveryDictionary = dictionary
        // Initialize all properties from dictionary
        guard let issuerString = dictionary["issuer"] as? String,
              let issuer = URL(string: issuerString) else {
            throw ServiceDiscoveryError.invalidURL("issuer")
        }
        self.issuer = issuer
        // ... Initialize other properties
    }
     */
}

// MARK: - Error Handling

public enum ServiceDiscoveryError: Error {
    case invalidJSON
    case missingRequiredFields
    case invalidURL(String)
}

// MARK: - Private Helpers

private extension OIDServiceDiscovery {
    static func dictionaryHasRequiredFields(_ dictionary: [String: Any]) -> Bool {
        let requiredFields = [
            "issuer",
            "authorization_endpoint",
            "token_endpoint",
            "jwks_uri",
            "response_types_supported",
            "subject_types_supported",
            "id_token_signing_alg_values_supported"
        ]
        
        return requiredFields.allSatisfy { dictionary[$0] != nil }
    }
}


struct OpenIDConnectDiscoveryDocument {
    let issuer: String = "https://example.com"
    let authorizationEndpoint: String = "https://example.com/authorize"
    let deviceAuthorizationEndpoint: String = "https://example.com/device_authorize"
    let tokenEndpoint: String = "https://example.com/token"
    let userinfoEndpoint: String = "https://example.com/userinfo"
    let jwksURI: String = "https://example.com/jwks"
    let registrationEndpoint: String = "https://example.com/register"
    let endSessionEndpoint: String = "https://example.com/logout"
    let scopesSupported: [String] = ["openid", "profile", "email"]
    let responseTypesSupported: [String] = ["code", "token", "id_token"]
    let responseModesSupported: [String] = ["query", "fragment"]
    let grantTypesSupported: [String] = ["authorization_code", "implicit", "refresh_token"]
    let acrValuesSupported: [String] = ["urn:mace:incommon:iap:silver"]
    let subjectTypesSupported: [String] = ["public", "pairwise"]
    let idTokenSigningAlgValuesSupported: [String] = ["RS256"]
    let idTokenEncryptionAlgValuesSupported: [String] = ["RSA1_5"]
    let idTokenEncryptionEncValuesSupported: [String] = ["A128CBC-HS256"]
    let userinfoSigningAlgValuesSupported: [String] = ["RS256"]
    let userinfoEncryptionAlgValuesSupported: [String] = ["RSA1_5"]
    let userinfoEncryptionEncValuesSupported: [String] = ["A128CBC-HS256"]
    let requestObjectSigningAlgValuesSupported: [String] = ["RS256"]
    let requestObjectEncryptionAlgValuesSupported: [String] = ["RSA1_5"]
    let requestObjectEncryptionEncValuesSupported: [String] = ["A128CBC-HS256"]
    let tokenEndpointAuthMethodsSupported: [String] = ["client_secret_basic", "client_secret_post"]
    let tokenEndpointAuthSigningAlgValuesSupported: [String] = ["RS256"]
    let displayValuesSupported: [String] = ["page", "popup"]
    let claimTypesSupported: [String] = ["normal", "aggregated"]
    let claimsSupported: [String] = ["sub", "name", "email"]
    let serviceDocumentation: String = "https://example.com/service_documentation"
    let claimsLocalesSupported: [String] = ["en", "fr"]
    let uiLocalesSupported: [String] = ["en", "fr"]
    let claimsParameterSupported: Bool = true
    let requestParameterSupported: Bool = true
    let requestURIParameterSupported: Bool = true
    let requireRequestURIRegistration: Bool = true
    let opPolicyURI: String = "https://example.com/policy"
    let opTosURI: String = "https://example.com/tos"
}
