import Testing
import Foundation
@testable import AppAuth

@Suite("URLQueryBuilder Tests")
struct URLQueryBuilderTests {
    @Test("Percent encode special characters")
    func percentEncodeSpecial() {
        #expect(URLQueryBuilder.percentEncode("hello world") == "hello%20world")
        #expect(URLQueryBuilder.percentEncode("a=b&c=d") == "a%3Db%26c%3Dd")
        #expect(URLQueryBuilder.percentEncode("test+value") == "test%2Bvalue")
    }

    @Test("Percent encode preserves unreserved characters")
    func percentEncodeUnreserved() {
        #expect(URLQueryBuilder.percentEncode("abc123") == "abc123")
        #expect(URLQueryBuilder.percentEncode("a-b_c.d~e") == "a-b_c.d~e")
    }

    @Test("Parse query string")
    func parseQuery() {
        let params = URLQueryBuilder.parseQuery("key1=value1&key2=value2&key3=hello%20world")

        #expect(params["key1"] == "value1")
        #expect(params["key2"] == "value2")
        #expect(params["key3"] == "hello world")
    }

    @Test("Parse empty query string")
    func parseEmptyQuery() {
        let params = URLQueryBuilder.parseQuery("")
        #expect(params.isEmpty)
    }

    @Test("Build query string")
    func buildQuery() {
        let query = URLQueryBuilder.buildQuery(from: [
            ("key1", "value1"),
            ("key2", "hello world"),
        ])

        #expect(query == "key1=value1&key2=hello%20world")
    }
}
