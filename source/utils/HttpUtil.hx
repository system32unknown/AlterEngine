package utils;

import haxe.Http;
import haxe.io.Bytes;

/**
 * Helper utilities for performing HTTP operations.
 *
 * Provides simple methods for GET and POST requests,
 * automatic redirect handling, and basic connectivity checks.
 */
final class HttpUtil {
	/**
	 * Value used for the `User-Agent` header in all requests.
	 */
	public static var userAgent:String = "request";

	/**
	 * Maximum number of redirects allowed before aborting a request.
	 */
	public static var maxRedirects:Int = 10;

	/**
	 * Retrieves the contents of a URL as a String.
	 *
	 * Redirects are followed automatically up to `maxRedirects`.
	 *
	 * @param url Target URL.
	 * @return Response body as text.
	 * @throws HttpError If the request fails.
	 */
	public static function requestText(url:String):String
		return cast fetch(url, false, 0);

	/**
	 * Retrieves the contents of a URL as raw Bytes.
	 *
	 * Redirects are followed automatically up to `maxRedirects`.
	 *
	 * @param url Target URL.
	 * @return Response body as bytes.
	 * @throws HttpError If the request fails.
	 */
	public static function requestBytes(url:String):Bytes
		return cast fetch(url, true, 0);

	/**
	 * Sends a POST request with key-value parameters.
	 *
	 * @param url Destination URL.
	 * @param params Map of parameters to include in the request body.
	 * @throws HttpError If the request fails.
	 */
	public static function postParameters(url:String, params:Map<String, String>):Void {
		var error:HttpError = null;

		var h:Http = makeHttp(url);
		for (k => v in params) h.addParameter(k, v);
		h.onError = (msg:String) -> error = new HttpError(msg, url);
		h.request(true);

		if (error != null) throw error;
	}

	/**
	 * Performs a lightweight connectivity check.
	 *
	 * Uses a minimal endpoint that returns a 204 response
	 * to determine whether outbound internet access is available.
	 *
	 * @return `true` if reachable, otherwise `false`.
	 */
	public static function hasInternet():Bool {
		try {
			requestText("https://connectivitycheck.gstatic.com/generate_204");
			return true;
		} catch (_:HttpError) return false;
	}

	/**
	 * Internal request handler with redirect support.
	 *
	 * Recursively follows redirects until a final response is received
	 * or the redirect limit is exceeded.
	 *
	 * @param url Initial request URL.
	 * @param asBytes Whether the response should be returned as Bytes.
	 * @param depth Current redirect depth.
	 * @return Response data (String or Bytes).
	 * @throws HttpError On failure, invalid redirect, or empty response.
	 */
	static function fetch(url:String, asBytes:Bool, depth:Int):Dynamic {
		if (depth > maxRedirects)
			throw new HttpError('Redirect limit ($maxRedirects) exceeded', url);

		var result:Dynamic = null;
		var error:HttpError = null;
		var redirectUrl:String = null;

		var h:Http = makeHttp(url);

		h.onStatus = (status:Int) -> {
			if (isRedirect(status)) {
				redirectUrl = h.responseHeaders.get("Location");
				if (redirectUrl == null) error = new HttpError("Missing Location header in redirect", url, status);
			}
		};

		if (asBytes) h.onBytes = (data:Bytes) -> if (redirectUrl == null) result = data; else h.onData = (data:String) -> if (redirectUrl == null) result = data;
		h.onError = (msg:String) -> error = new HttpError(msg, url);

		h.request(false);

		if (error != null) throw error;
		if (redirectUrl != null) return fetch(redirectUrl, asBytes, depth + 1);
		if (result == null) throw new HttpError("Empty response", url);

		return result;
	}

	/**
	 * Creates and configures an `Http` instance.
	 *
	 * Applies shared headers such as `User-Agent`.
	 *
	 * @param url Target URL.
	 * @return Configured Http object.
	 */
	static inline function makeHttp(url:String):Http {
		var h:Http = new Http(url);
		h.setHeader("User-Agent", userAgent);
		return h;
	}

	/**
	 * Determines whether a status code represents an HTTP redirect.
	 *
	 * Recognized redirect codes:
	 * - 301 (Moved Permanently)
	 * - 302 (Found)
	 * - 307 (Temporary Redirect)
	 * - 308 (Permanent Redirect)
	 *
	 * @param status HTTP status code.
	 * @return `true` if redirect, otherwise `false`.
	 */
	static function isRedirect(status:Int):Bool {
		return switch (status) {
			case 301 | 302 | 307 | 308:
				Logs.traceColored([
					{fgColor: BLUE, text: "[Connection Status] "},
					{fgColor: YELLOW, text: "Redirected with status code: "},
					{fgColor: GREEN, text: Std.string(status)}
				], WARNING);
				true;
			case _: false;
		}
	}
}

/**
 * Represents an HTTP-related failure.
 *
 * Stores the error message, request URL, and optional status code.
 */
private class HttpError {
	/**
	 * Human-readable error message.
	 */
	public final message:String;

	/**
	 * URL associated with the failed request.
	 */
	public final url:String;

	/**
	 * HTTP status code, or -1 if unavailable.
	 */
	public final status:Int;

	/**
	 * Creates a new HttpError instance.
	 *
	 * @param message Description of the failure.
	 * @param url Request URL.
	 * @param status Optional HTTP status code.
	 */
	public function new(message:String, url:String, status:Int = -1) {
		this.message = message;
		this.url = url;
		this.status = status;
	}

	/**
	 * Converts the error into a readable string format.
	 *
	 * @return Formatted error details.
	 */
	public function toString():String {
		final parts:Array<String> = ['[HttpError]'];
		if (status != -1) parts.push('Status: $status');
		parts.push('URL: $url');
		parts.push('Message: $message');
		return parts.join(' | ');
	}
}
