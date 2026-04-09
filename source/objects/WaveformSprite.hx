package objects;

import openfl.geom.Rectangle;
import openfl.media.Sound;
import lime.media.AudioBuffer;

/**
 * A sprite that renders an audio waveform from a sound source.
 *
 * Supported input types for the `sound` constructor argument:
 *   - `FlxSound`   — HaxeFlixel managed sound
 *   - `openfl.media.Sound` — raw OpenFL sound
 *   - `lime.media.AudioBuffer` — raw PCM buffer
 *
 * Only 16-bit little-endian PCM audio is currently supported.
 *
 * @author YoshiCrafter (improved)
 */
class WaveformSprite extends FlxSprite {
	/**
	 * The underlying PCM audio buffer. May be null if the source was invalid.
	 */
	var buffer:AudioBuffer;

	/**
	 * The OpenFL Sound that owns the buffer (kept alive to avoid GC).
	 */
	var sound:Sound;

	/**
	 * Maximum positive integer value for one sample, used to normalise
	 * amplitude to the range [0, 1].
	 * For 16-bit audio this is 32767 (2^15 - 1).
	 */
	var peak:Float = 0;

	/**
	 * Number of bytes per sample (bitsPerSample / 8).
	 */
	var bytesPerSample:Int = 2;

	/**
	 * False when the constructor received an unsupported/null source.
	 */
	var valid:Bool = true;

	public override function destroy():Void {
		super.destroy();
		if (buffer != null) {
			buffer.data.buffer = null;
			buffer.dispose();
			buffer = null;
		}
	}

	/**
	 * @param x      Sprite x position.
	 * @param y      Sprite y position.
	 * @param sound  A `FlxSound`, `openfl.media.Sound`, or `AudioBuffer`.
	 * @param w      Width of the rendered waveform in pixels.
	 * @param h      Height of the rendered waveform in pixels.
	 */
	public function new(x:Float, y:Float, sound:Dynamic, w:Int, h:Int) @:privateAccess {
		super(x, y);

		if (Std.isOfType(sound, FlxSound)) {
			this.sound = cast(sound, FlxSound)._sound;
			this.buffer = this.sound.__buffer;
		} else if (Std.isOfType(sound, Sound)) {
			this.sound = cast(sound, Sound);
			this.buffer = this.sound.__buffer;
		} else if (Std.isOfType(sound, AudioBuffer)) {
			this.buffer = cast(sound, AudioBuffer);
		} else {
			valid = false;
			return;
		}

		if (buffer == null || buffer.data == null || buffer.data.buffer == null) {
			valid = false;
			return;
		}

		// Cache derived constants so generate() doesn't recompute them each call.
		bytesPerSample = Std.int(buffer.bitsPerSample / 8);
		peak = Math.pow(2, buffer.bitsPerSample - 1) - 1;

		makeGraphic(w, h, 0x00000000, true); // transparent
	}

	/**
	 * Render the waveform for a byte-offset range within the PCM buffer.
	 *
	 * Both `startByte` and `endByte` are clamped and aligned to sample
	 * boundaries automatically.
	 *
	 * @param startByte First byte offset in the raw PCM data (inclusive).
	 * @param endByte   Last  byte offset in the raw PCM data (exclusive).
	 */
	public function generate(startByte:Int, endByte:Int):Void {
		if (!valid) return;

		final data:lime.utils.ArrayBuffer = buffer.data.buffer;
		final totalBytes:Int = data.length;

		// Align to sample boundaries and clamp to valid range.
		startByte = Std.int(Math.max(0, startByte - (startByte % bytesPerSample)));
		endByte = Std.int(Math.min(totalBytes, endByte - (endByte % bytesPerSample)));

		if (startByte >= endByte) return;

		final span:Int = endByte - startByte;
		final imgW:Int = pixels.width;
		final imgH:Int = pixels.height;
		// Number of bytes each pixel row represents.
		final rowBytes:Int = Std.int(Math.max(bytesPerSample, span / imgH));

		pixels.lock();
		pixels.fillRect(new Rectangle(0, 0, imgW, imgH), 0x00000000);

		for (row in 0...imgH) {
			// Byte offset of the start of this row's slice.
			var sliceStart:Int = startByte + Std.int(span * (row / imgH));
			sliceStart -= sliceStart % bytesPerSample;

			var sliceEnd:Int = Std.int(Math.min(endByte, sliceStart + rowBytes));
			sliceEnd -= sliceEnd % bytesPerSample;

			// Find the peak absolute amplitude within this slice.
			var maxAmp:Int = 0;
			var pos:Int = sliceStart;
			while (pos < sliceEnd) {
				// Read one 16-bit signed little-endian sample.
				var sample:Int = data.get(pos) | (data.get(pos + 1) << 8);
				// Reinterpret as signed.
				if (sample >= 0x8000) sample -= 0x10000;
				var amp:Int = sample < 0 ? -sample : sample;
				if (amp > maxAmp) maxAmp = amp;
				pos += bytesPerSample;
			}

			// Map amplitude to pixel width (centred horizontally).
			var barWidth:Float = (maxAmp / peak) * imgW;
			var barX:Float = (imgW - barWidth) / 2;
			pixels.fillRect(new Rectangle(barX, row, barWidth, 1), FlxColor.WHITE);
		}
		pixels.unlock();
	}

	/**
	 * Render the waveform for a time range expressed in milliseconds.
	 *
	 * @param startMs Start of the window in milliseconds.
	 * @param endMs End of the window in milliseconds.
	 */
	public function generateFromTime(startMs:Float, endMs:Float):Void {
		if (!valid) return;

		final msToBytes:Float = (buffer.sampleRate / 1000.0) * buffer.channels * bytesPerSample;
		generate(Std.int(startMs * msToBytes), Std.int(endMs * msToBytes));
	}
}