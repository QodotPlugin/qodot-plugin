class_name QodotDependencies

const PROTOCOL := "https"
const GITHUB_DOMAIN := "github.com"
const GIT_USER := "QodotPlugin"
const RELEASE_DOWNLOADS := "releases/download"
const DEPENDENCY_TAG := "v1.7.0"

static func get_platform_string() -> String:
	match OS.get_name():
		"Windows":
			return "win64"
		"OSX":
			return "osx"
		"X11":
			return "x11"
	return "unsupported"

static func get_platform_library_extension() -> String:
	match OS.get_name():
		"Windows":
			return "dll"
		"OSX":
			return "dylib"
		"X11":
			return "so"
	return "unsupported"

static func format_github_release_download_url(repo: String, artifact: String) -> String:
	return "%s://%s/%s/%s/%s/%s/%s" % [PROTOCOL, GITHUB_DOMAIN, GIT_USER, repo, RELEASE_DOWNLOADS, DEPENDENCY_TAG, artifact]

static func get_dependencies() -> Dictionary:
	var platform_string := get_platform_string()
	var platform_extension := get_platform_library_extension()

	var libqodot_destination := "res://addons/qodot/bin/%s/libqodot.%s" % [platform_string, platform_extension]
	var libmap_destination := "res://addons/qodot/bin/%s/libmap.%s" % [platform_string, platform_extension]

	var libqodot_source := format_github_release_download_url("libqodot", "libqodot.%s" % get_platform_library_extension())
	var libmap_source := format_github_release_download_url("libmap", "libmap.%s" % get_platform_library_extension())

	return {
		libqodot_destination: libqodot_source,
		libmap_destination: libmap_source
	}

static func check_dependencies(http_request: HTTPRequest) -> void:
	var dependencies = get_dependencies()
	for dependency in dependencies:
		if not check_dependency(http_request, dependency, dependencies[dependency]):
			var result = yield(http_request, "request_completed")
			match result[0]:
				HTTPRequest.RESULT_SUCCESS:
					match result[1]:
						200:
							print("Download complete")
						_:
							print("Download failed")
							var dir = Directory.new()
							dir.remove(dependency)
				HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
					printerr("Error: Chunked body size mismatch")
				HTTPRequest.RESULT_CANT_CONNECT:
					printerr("Error: Unable to connect")
				HTTPRequest.RESULT_CANT_RESOLVE:
					printerr("Error: Unable to resolve host")
				HTTPRequest.RESULT_CONNECTION_ERROR:
					printerr("Error: Connection error")
				HTTPRequest.RESULT_SSL_HANDSHAKE_ERROR:
					printerr("Error: SSL handshake error")
				HTTPRequest.RESULT_NO_RESPONSE:
					printerr("Error: No response")
				HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
					printerr("Error: Request body size limit exceeded")
				HTTPRequest.RESULT_REQUEST_FAILED:
					printerr("Error: Request failed")
				HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
					printerr("Error: Unable to open file")
				HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
					printerr("Error: Failed to write file")
				HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
					printerr("Error: Redirect limit reached")
				HTTPRequest.RESULT_TIMEOUT:
					printerr("Error: Request timed out")

static func check_dependency(http_request: HTTPRequest, dependency: String, url: String) -> bool:
	print("Checking dependency ", dependency)

	var dir = Directory.new()
	if dir.file_exists(dependency):
		print("Dependency satisfied")
		return true

	var dependency_comps = dependency.split("/")
	dependency_comps.resize(dependency_comps.size() - 1)
	var dependency_dir = dependency_comps.join("/")

	if not dir.dir_exists(dependency_dir):
		dir.make_dir_recursive(dependency_dir)

	print("Dependency unsatisfied, downloading from ", url)
	http_request.download_file = dependency
	var err = http_request.request(url);

	match err:
		OK:
			print("HTTP request created")
		ERR_UNCONFIGURED:
			printerr("Error: HTTP request unconfigured")
		ERR_BUSY:
			printerr("Error: HTTP request busy")
		ERR_INVALID_PARAMETER:
			printerr("Error: HTTP request invalid parameter")
		ERR_CANT_CONNECT:
			printerr("Error: HTTP request unable to connect")

	return false
