import Foundation
import Testing
@testable import NotchAgentDeskProtocol

@Test func frameRoundTrip() throws {
    let payload = Data(#"{"product":"NotchAgent Desk","nonce":42}"#.utf8)
    let encoded = try DeskFrameCodec.encode(.init(type: .hello, sequence: 7, payload: payload))
    #expect(encoded.last == 0)
    let decoded = try DeskFrameCodec.decodePacket(encoded.dropLast())
    #expect(decoded == .init(type: .hello, sequence: 7, payload: payload))
}

@Test func partialStreamRoundTrip() throws {
    let encoded = try DeskFrameCodec.encode(.init(type: .heartbeat, sequence: 9, payload: Data([0, 1, 0, 2])))
    var decoder = DeskFrameStreamDecoder()
    #expect(decoder.append(encoded.prefix(3)).isEmpty)
    let result = decoder.append(encoded.dropFirst(3))
    #expect(result.count == 1)
    #expect(try result[0].get().type == .heartbeat)
}

@Test func checksumFailureIsRejected() throws {
    var encoded = try DeskFrameCodec.encode(.init(type: .snapshot, sequence: 1, payload: Data("safe".utf8)))
    encoded[encoded.index(encoded.startIndex, offsetBy: 4)] ^= 0x20
    #expect(throws: (any Error).self) {
        try DeskFrameCodec.decodePacket(encoded.dropLast())
    }
}

