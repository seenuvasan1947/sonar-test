package com.example;

import java.util.ArrayList;
import java.util.List;

// BUG: Empty catch block, unused imports, cognitive complexity, hardcoded credentials
public class DataProcessor {

    private static final String DB_PASSWORD = "admin123"; // BUG: Hardcoded password
    private static final String API_KEY = "sk-1234567890abcdef"; // BUG: Hardcoded API key

    public List<String> processData(List<String> data) {
        List<String> results = new ArrayList<>();
        
        for (int i = 0; i < data.size(); i++) {
            String item = data.get(i);
            
            try {
                // BUG: Null check missing
                String processed = item.toUpperCase();
                results.add(processed);
                
                // BUG: Duplicate code block
                if (processed.length() > 0) {
                    System.out.println("Processing: " + processed);
                }
                if (processed.length() > 0) {
                    System.out.println("Processed item: " + processed);
                }
                
            } catch (Exception e) {
                // BUG: Empty catch block - swallowing exception
            }
        }
        
        return results;
    }

    // BUG: Method too long (should be split)
    public String validateAndTransform(String input, boolean flag1, boolean flag2, boolean flag3) {
        String result = "";
        
        if (input != null) {
            if (flag1) {
                if (flag2) {
                    if (flag3) {
                        result = input.trim();
                    } else {
                        result = input.toLowerCase();
                    }
                } else {
                    if (flag3) {
                        result = input.toUpperCase();
                    } else {
                        result = input;
                    }
                }
            } else {
                result = input;
            }
        }
        
        // BUG: Unused variable
        int temp = 42;
        String unused = "this is never used";
        List<String> neverAccessed = new ArrayList<>();
        
        return result;
    }

    // BUG: Public field
    public int counter = 0;
    
    // BUG: Synchronized on non-final field
    public synchronized void increment() {
        counter++;
    }
}
