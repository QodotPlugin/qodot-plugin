class_name QodotThreadPool
tool

export(int) var max_threads = 4 setget set_max_threads
export(int) var bucket_size = 4 setget set_bucket_size

var free_threads = []
var busy_threads = []
var pending_jobs = []

signal jobs_complete(results)

var job_counter = 0
var job_results = {}

class PoolThread extends Thread:
	var semaphore: Semaphore = null
	var job_bucket: Array = []
	var results: Dictionary = {}
	var _running = true

	signal jobs_finished(thread, results)

	func _init():
		semaphore = Semaphore.new()
		start(self, "_run_thread")

	func _run_thread(userdata):
		while true:
			semaphore.wait()

			if not _running:
				return

			results.clear()
			while self.job_bucket.size() > 0:
				var job: Job = job_bucket.pop_front()
				results[job.id] = job.run()

			call_deferred("_jobs_finished")

	func _jobs_finished():
		emit_signal("jobs_finished", self, results)

	func finish():
		_running = false
		semaphore.post()
		wait_to_finish()

class Job:
	var id: int
	var target: Object
	var func_name: String
	var params

	func _init(id: int, target: Object, func_name: String, params):
		self.id = id
		self.target = target
		self.func_name = func_name
		self.params = params

	func run():
		return self.target.call(self.func_name, self.params)

# Setters
func set_max_threads(new_max_threads):
	if(max_threads != new_max_threads):
		max_threads = new_max_threads

		while free_threads.size() > max_threads:
			remove_thread()

		while free_threads.size() + busy_threads.size() < max_threads:
			add_thread()

func set_bucket_size(new_bucket_size):
	if(bucket_size != new_bucket_size):
		bucket_size = new_bucket_size

# Interface
func add_thread():
	var thread = PoolThread.new()
	free_threads.append(thread)
	thread.connect("jobs_finished", self, "finish_thread_jobs")

func remove_thread():
	if(free_threads.size() > 0):
		var thread = free_threads.pop_back()
		if thread.is_active():
			thread.finish()

func add_thread_job(target, func_name, params):
	var job_id = job_counter
	job_counter += 1

	pending_jobs.append(Job.new(job_id, target, func_name, params))

	if(free_threads.size() == 0 && free_threads.size() + busy_threads.size() < max_threads):
		add_thread()

	return job_id

func start_thread_jobs():
	while pending_jobs.size() > 0 && free_threads.size() > 0:
		var thread = free_threads.pop_front()

		while thread.job_bucket.size() < bucket_size && pending_jobs.size() > 0:
			thread.job_bucket.append(pending_jobs.pop_front())

		thread.semaphore.post()
		busy_threads.append(thread)

func run_thread_jobs(userdata):
	var thread = userdata[0]
	var job_bucket = userdata[1]

	var results = {}

	for job in job_bucket:
		results[job.id] = job.run()

	call_deferred("finish_thread_jobs", thread)

	return results

func finish_thread_jobs(thread, results):
	for job_id in results:
		job_results[job_id] = results[job_id]

	busy_threads.remove(busy_threads.find(thread))

	if(free_threads.size() < max_threads):
		free_threads.append(thread)
	else:
		thread.finish()

	if(busy_threads.size() == 0 && pending_jobs.size() == 0):
		emit_signal("jobs_complete", job_results)
		job_results.clear()
		job_counter = 0
	else:
		start_thread_jobs()

func jobs_running():
	return busy_threads.size()

func jobs_pending():
	return pending_jobs.size()

func finish():
	for thread in free_threads:
		if thread.is_active():
			thread.finish()

	for thread in busy_threads:
		if thread.is_active():
			thread.finish()
