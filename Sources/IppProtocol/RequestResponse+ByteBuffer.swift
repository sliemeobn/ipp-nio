import NIOCore

public extension IppRequest {
    /// Reads an IPP request from the given buffer.
    ///
    /// This method will throw an error if the buffer does not contain a valid IPP request.
    /// The reader index of the buffer will be advanced to the end of the IPP request.
    init(buffer: inout ByteBuffer) throws {
        do {
            self = try buffer.readIppCodable()
        } catch let error as ParsingError {
            throw IppParsingError(readerIndex: buffer.readerIndex, parsingError: error)
        }
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
        do {
            self = try buffer.readIppCodable()
        } catch let error as ParsingError {
            throw IppParsingError(readerIndex: buffer.readerIndex, parsingError: error)
        }
    }

    /// Writes this IPP response to the given buffer.
    func write(to buffer: inout ByteBuffer) {
        buffer.writeIppCodable(self)
    }
}

/// An error that occurred while parsing an IPP request or response.
///
/// This error contains the reader index of the buffer at which the parsing error occurred.
public struct IppParsingError: Error, CustomStringConvertible {
    public let readerIndex: Int
    internal let parsingError: ParsingError

    public var description: String {
        "Parsing error at index \(readerIndex): \(parsingError)"
    }
}
