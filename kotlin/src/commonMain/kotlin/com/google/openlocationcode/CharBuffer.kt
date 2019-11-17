package com.google.openlocationcode

class CharBuffer(private val maxLen: Int, private val paddingChar: Char = ' ') {
    private var actualLength = 0
    private val buffer = CharArray(maxLen) { paddingChar }

    val length: Int get() = actualLength

    fun append(c: Char) {
        buffer[actualLength++] = c
    }

    operator fun get(index: Int): Char {
        require(index in 0 until actualLength) { "Index $index is out of range 0..$actualLength" }
        return buffer[index]
    }

    operator fun set(index: Int, value: Char) {
        require(index in 0 until actualLength) { "Index $index is out of range 0..$actualLength" }
        buffer[index] = value
    }

    fun toArray(): CharArray = buffer.sliceArray(0 until actualLength)
}