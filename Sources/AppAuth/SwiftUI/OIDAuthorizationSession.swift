//
//  OIDAuthorizationSession.swift
//  AppAuth
//
//  Created by Charysz, Wojciech on 17.03.25.
//  Copyright © 2025 OpenID Foundation. All rights reserved.
//
import SwiftUI
import AuthenticationServices

@available(iOS 16.4, macOS 13.3, *)
public struct OIDAuthorizationSession: ViewModifier {
  private let configuration: OIDServiceConfiguration
  private let clientId: String
  private let clientSecret: String?
  private let scopes: [String]
  private let redirectScheme: String
  private let prefersEphemeralWebBrowserSession: Bool
  private let callback: (OIDAuthState?) -> Void
  
  @Environment(\.webAuthenticationSession) private var webAuthenticationSession
  
  public init(
    configuration: OIDServiceConfiguration,
    clientId: String,
    clientSecret: String? = nil,
    scopes: [String],
    redirectScheme: String,
    prefersEphemeralWebBrowserSession: Bool = false,
    callback: @escaping (OIDAuthState?) -> Void
  ) {
    self.configuration = configuration
    self.clientId = clientId
    self.clientSecret = clientSecret
    self.scopes = scopes
    self.redirectScheme = redirectScheme
    self.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
    self.callback = callback
  }
  
  public func body(content: Content) -> some View {
    content
      .task {
        do {
          let callbackURL = try await webAuthenticationSession.authenticate(
            using: makeAuthorizationRequestURL(),
            callbackURLScheme: redirectScheme,
            preferredBrowserSession: prefersEphemeralWebBrowserSession ? .ephemeral : .shared
          )
          handleAuthCallback(callbackURL: callbackURL, error: nil)
        } catch {
          handleAuthCallback(callbackURL: nil, error: error)
        }
      }
  }
  
  private func makeAuthorizationRequestURL() -> URL {
    let request = OIDAuthorizationRequest(
      configuration: configuration,
      clientId: clientId,
      clientSecret: clientSecret,
      scopes: scopes,
      redirectURL: URL(string: "\(redirectScheme)://oauth2callback")!,
      responseType: OIDResponseTypeCode,
      additionalParameters: nil
    )
    
    return request.authorizationRequestURL()
  }
  
  private func handleAuthCallback(callbackURL: URL?, error: Error?) {
      guard error == nil, let callbackURL = callbackURL else {
          callback(nil)
          return
      }
      
      let request = OIDAuthorizationRequest(
          configuration: configuration,
          clientId: clientId,
          clientSecret: clientSecret,
          scopes: scopes,
          redirectURL: URL(string: "\(redirectScheme)://oauth2callback")!,
          responseType: OIDResponseTypeCode,
          additionalParameters: nil
      )
    
    let response = OIDAuthorizationResponse(request: request, parameters: callbackURL.parameters)
      
      guard let tokenExchangeRequest = response.tokenExchangeRequest() else {
          callback(nil)
          return
      }
      
      let authState = OIDAuthState(authorizationResponse: response)
      
      OIDAuthorizationService.perform(tokenExchangeRequest) { tokenResponse, error in
          if let tokenResponse = tokenResponse {
              authState.update(with: tokenResponse, error: nil)
              callback(authState)
          } else {
              callback(nil)
          }
      }
  }
}

// Helper extension to parse URL parameters
private extension URL {
  var parameters: [String: any NSCopying & NSObjectProtocol] {
    guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
      return [:]
    }
    return queryItems.reduce(into: [:]) { result, item in
      result[item.name] = NSString(string: item.value ?? "")
    }
  }
}

// Extension to make it easier to use
@available(iOS 16.4, macOS 13.3, *)
extension View {
  public func oauth2Authorization(
    configuration: OIDServiceConfiguration,
    clientId: String,
    clientSecret: String? = nil,
    scopes: [String],
    redirectScheme: String,
    prefersEphemeralWebBrowserSession: Bool = false,
    callback: @escaping (OIDAuthState?) -> Void
  ) -> some View {
    modifier(OIDAuthorizationSession(
      configuration: configuration,
      clientId: clientId,
      clientSecret: clientSecret,
      scopes: scopes,
      redirectScheme: redirectScheme,
      prefersEphemeralWebBrowserSession: prefersEphemeralWebBrowserSession,
      callback: callback
    ))
  }
}
