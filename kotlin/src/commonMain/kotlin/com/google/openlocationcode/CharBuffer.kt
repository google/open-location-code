package com.google.openlocationcode

/**
 * A wrapper around an array to act in replacement for StringBuilder which does not allow overwrite specific characters
 * nor does StringBuilder in Kotlin common allow conversion to a CharArray without using a (currently) experimental
 * API, this can be removed when that is allowed.
 */
internal class CharBuffer(private val maxLen: Int, private val paddingChar: Char = ' ') {
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