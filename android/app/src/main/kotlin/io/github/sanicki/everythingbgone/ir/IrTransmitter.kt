package io.github.sanicki.everythingbgone

interface IrTransmitter {
    fun transmitRaw(frequencyHz: Int, patternUs: IntArray): Boolean
}
