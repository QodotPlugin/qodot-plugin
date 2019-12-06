class_name QodotThreadPool
tool

export(int) var max_threads = 4 setget set_max_threads
export(int) var bucket_size = 4 setget set_bucket_size

var free_threads = []
var busy_threads = []
var pending_jobs = []

signal job_complete(job_id, job_result)
signal jobs_complete

var job_counter = 0

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
	free_threads.append(Thread.new())

func remove_thread():
	free_threads.pop_back()

func add_thread_job(target, func_name, params):
	var job_id = job_counter
	job_counter += 1

	pending_jobs.append([job_id, target, func_name, params])

	if(free_threads.size() == 0 && free_threads.size() + busy_threads.size() < max_threads):
		add_thread()

	return job_id

func start_thread_jobs():
	while pending_jobs.size() > 0 && free_threads.size() > 0:
		var thread = free_threads.pop_front()

		var job_bucket = []
		while job_bucket.size() < bucket_size && pending_jobs.size() > 0:
			var job = pending_jobs.pop_front()
			job_bucket.append(job)

		thread.start(self, "run_thread_jobs", [thread, job_bucket])
		busy_threads.append(thread)

func run_thread_jobs(userdata):
	var thread = userdata[0]
	var job_bucket = userdata[1]

	var results = {}

	for job in job_bucket:
		var job_id = job[0]
		var target = job[1]
		var func_name = job[2]
		var params = job[3]

		results[job_id] = target.call(func_name, params)

	call_deferred("finish_thread_jobs", thread)

	return results

func finish_thread_jobs(thread):
	var results = thread.wait_to_finish()

	for job_id in results:
		emit_signal("job_complete", job_id, results[job_id])

	busy_threads.remove(busy_threads.find(thread))

	if(free_threads.size() < max_threads):
		free_threads.append(thread)

	if(busy_threads.size() == 0 && pending_jobs.size() == 0):
		emit_signal("jobs_complete")
		job_counter = 0
	else:
		start_thread_jobs()

func jobs_running():
	return busy_threads.size()

func jobs_pending():
	return pending_jobs.size()

func wait_to_finish():
	for thread in busy_threads:
		thread.wait_to_finish()
