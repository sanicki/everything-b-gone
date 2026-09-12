package com.example.everythingbgone

interface IrTransmitter {
    fun transmitRaw(frequencyHz: Int, patternUs: IntArray): Boolean
}
