package com.k8.performanceTesting.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class DemoController {

    @GetMapping("/api/hello")
    public String hello() {
        return "Hello from Spring Boot running on Kubernetes!";
    }

    @GetMapping("/api/status")
    public Map<String, String> status() {
        return Map.of(
                "application", "k8s-demo",
                "status", "UP"
        );
    }
    @GetMapping("/api/load")
    public Map<String, Object> generateLoad(
            @RequestParam(defaultValue = "5") int seconds) {

        seconds = Math.max(1, Math.min(seconds, 30));

        long endTime = System.nanoTime()
                + seconds * 1_000_000_000L;

        double result = 0;

        while (System.nanoTime() < endTime) {
            result += Math.sqrt(Math.random() * 10000);
        }

        return Map.of(
                "message", "CPU load completed",
                "pod", System.getenv("HOSTNAME"),
                "seconds", seconds
        );
    }
}