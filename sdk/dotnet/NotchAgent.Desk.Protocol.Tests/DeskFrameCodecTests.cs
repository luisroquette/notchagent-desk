using System.Text;
using NotchAgent.Desk.Protocol;

namespace NotchAgent.Desk.Protocol.Tests;

public sealed class DeskFrameCodecTests
{
    [Fact]
    public void FrameRoundTrips()
    {
        var payload = Encoding.UTF8.GetBytes("{\"product\":\"NotchAgent Desk\",\"nonce\":42}");
        var encoded = DeskFrameCodec.Encode(new DeskFrame(DeskFrameType.Hello, 7, payload));

        Assert.Equal(0, encoded[^1]);
        var decoded = DeskFrameCodec.DecodePacket(encoded.AsSpan(0, encoded.Length - 1));
        Assert.Equal(DeskFrameType.Hello, decoded.Type);
        Assert.Equal(7u, decoded.Sequence);
        Assert.Equal(payload, decoded.Payload);
    }

    [Fact]
    public void PartialStreamRoundTrips()
    {
        var encoded = DeskFrameCodec.Encode(new DeskFrame(DeskFrameType.Heartbeat, 9, [0, 1, 0, 2]));
        var decoder = new DeskFrameStreamDecoder();

        Assert.Empty(decoder.Append(encoded.AsSpan(0, 3)));
        var frames = decoder.Append(encoded.AsSpan(3));
        Assert.Single(frames);
        Assert.Equal(DeskFrameType.Heartbeat, frames[0].Type);
    }

    [Fact]
    public void CorruptedPacketIsRejected()
    {
        var encoded = DeskFrameCodec.Encode(new DeskFrame(DeskFrameType.Snapshot, 1, Encoding.UTF8.GetBytes("safe")));
        encoded[4] ^= 0x20;
        Assert.Throws<DeskProtocolException>(() => DeskFrameCodec.DecodePacket(encoded.AsSpan(0, encoded.Length - 1)));
    }
}
