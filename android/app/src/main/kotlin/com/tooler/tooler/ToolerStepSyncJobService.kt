package com.tooler.tooler

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context

/**
 * TOOLER HARDWARE STEP HUB SYNC JOB
 * ---------------------------------------------------------------------------
 * Uses Android's native JobScheduler (~15-min Doze-friendly cadence) to read
 * the device's always-on hardware step sensor hub without running any 24/7
 * Foreground Service, without showing an ongoing notification, and without
 * showing Tooler in Android's "Active apps" drawer.
 */
class ToolerStepSyncJobService : JobService() {

    companion object {
        const val JOB_ID = 5121

        fun schedule(context: Context) {
            try {
                if (!ToolerStepService.hasActivityPermission(context)) return
                val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as? JobScheduler ?: return
                if (scheduler.getPendingJob(JOB_ID) != null) return

                val info = JobInfo.Builder(
                    JOB_ID,
                    ComponentName(context, ToolerStepSyncJobService::class.java)
                )
                    .setPeriodic(15 * 60 * 1000L)
                    .setPersisted(true)
                    .setRequiresBatteryNotLow(false)
                    .build()

                scheduler.schedule(info)
            } catch (_: Throwable) {}
        }
    }

    override fun onStartJob(params: JobParameters?): Boolean {
        if (!ToolerStepService.hasActivityPermission(applicationContext)) {
            return false
        }
        ToolerStepService.syncHardwareSnapshotOnce(applicationContext) {
            try {
                jobFinished(params, false)
            } catch (_: Throwable) {}
        }
        return true
    }

    override fun onStopJob(params: JobParameters?): Boolean {
        return false
    }
}
