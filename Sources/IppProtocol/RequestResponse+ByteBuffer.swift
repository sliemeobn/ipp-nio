import NIOCore

public extension IppRequest {
    /// Reads an IPP request from the given buffer.
    /// 
    /// This method will throw an error if the buffer does not contain a valid IPP request.
    /// The reader index of the buffer will be advanced to the end of the IPP request.
    init(buffer: inout ByteBuffer) throws {
        self = try buffer.readIppCodable()
    }

    /// Writes this IPP request to the given buffer.
    func write(to buffer: inout ByteBuffer) {
        buffer.writeIppCodable(self)
    }
}

public extension IppResponse {
    /// Reads an IPP response from the given buffer.
    /// 
    /// This method will throw an error if the buffer does not contain a valid IPP response.
    /// The reader index of the buffer will be advanced to the end of the IPP response.
    init(buffer: inout ByteBuffer) throws {
        self = try buffer.readIppCodable()
    }

    /// Writes this IPP response to the given buffer.
    func write(to buffer: inout ByteBuffer) {
        buffer.writeIppCodable(self)
    }
}