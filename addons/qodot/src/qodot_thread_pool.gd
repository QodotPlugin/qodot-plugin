class_name QodotThreadPool
tool

export(int) var max_threads = 4 setget set_max_threads

var free_threads = []
var busy_threads = []
var pending_jobs = []

signal jobs_complete

# Setters
func set_max_threads(new_max_threads):
	if(max_threads != new_max_threads):
		max_threads = new_max_threads

		if(free_threads.size() > max_threads):
			for idx in range(max_threads, free_threads.size()):
				free_threads.pop_back()

		while(free_threads.size() + busy_threads.size() < max_threads):
			free_threads.append(Thread.new())

# Interface
func add_threads(count):
	for idx in range(0, count):
		free_threads.append(Thread.new())

func add_thread_job(job):
	pending_jobs.append(job)

	if(free_threads.size() == 0 && free_threads.size() + busy_threads.size() < max_threads):
		add_threads(1)

	start_thread_job()

func start_thread_job():
	if(pending_jobs.size() > 0):
		if(free_threads.size() > 0):
			var job = pending_jobs.pop_front()
			var thread = free_threads.pop_front()
			var params = job[2]
			params.append(thread)
			thread.start(job[0], job[1], params)
			busy_threads.append(thread)

func finish_thread_job(thread):
	thread.wait_to_finish()
	busy_threads.remove(busy_threads.find(thread))

	if(free_threads.size() < max_threads):
		free_threads.append(thread)

	if(busy_threads.size() == 0 && pending_jobs.size() == 0):
		emit_signal("jobs_complete")

	start_thread_job()

func jobs_running():
	return busy_threads.size()

func jobs_pending():
	return pending_jobs.size()

func wait_to_finish():
	for thread in busy_threads:
		thread.wait_to_finish()
