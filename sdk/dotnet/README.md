# .NET host protocol SDK

This .NET 8 package implements the exact COBS + CRC-32 frame contract used by
NotchAgent Desk protocol 1.1. It is intended for the Windows NotchAgent host.

The codec is Windows-CI validated. Physical USB discovery, reconnect, DPI, tray,
and installer gates remain tracked in the repository compatibility matrix; this
SDK alone does not promote Windows support from Beta to Stable.

