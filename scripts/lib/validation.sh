#!/bin/bash
# validation.sh - Context Engineering Validation Library
# Ensures ctx.json meets the revolution's standards

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/json.sh"
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Schema validation with jq
validate_ctx_schema() {
    local json_file="$1"
    local schema_file="$(dirname "${BASH_SOURCE[0]}")/schema/ctx.schema.json"
    
    if [[ ! -f "$json_file" ]]; then
        log_error "Context file not found: $json_file"
        return 1
    fi
    
    if [[ ! -f "$schema_file" ]]; then
        log_error "Schema file not found: $schema_file"
        return 1
    fi
    
    # Basic JSON validation first
    if ! jq empty "$json_file" 2>/dev/null; then
        log_error "Invalid JSON format in context file"
        return 1
    fi
    
    log_info "${BLUE}🔍 Validating context against schema...${NC}"
    
    # Simplified schema validation for context engineering
    local validation_result
    validation_result=$(jq -r '
        def validate_node:
            type == "object" and 
            has("type") and 
            has("name") and
            (.type == "directory" or .type == "file") and
            (if .type == "directory" then (has("contents") and (.contents | type == "array")) else true end);
        
        if type != "array" then "ERROR: Root must be array"
        elif length == 0 then "ERROR: Context cannot be empty"
        else
            if map(validate_node) | all then "VALID"
            else "ERROR: Invalid node structure detected"
            end
        end
    ' "$json_file" 2>/dev/null || echo "ERROR: JSON processing failed")
    
    if [[ "$validation_result" == "VALID" ]]; then
        log_success "✅ Context schema validation passed"
        return 0
    else
        log_error "❌ Schema validation failed: $validation_result"
        return 1
    fi
}

# Calculate context quality metrics
calculate_context_metrics() {
    local json_file="$1"
    
    if [[ ! -f "$json_file" ]]; then
        log_error "Context file not found: $json_file"
        return 1
    fi
    
    log_info "${BLUE}📊 Calculating context engineering metrics...${NC}"
    
    local metrics
    metrics=$(jq -r '
        def count_nodes:
            if type == "array" then
                map(count_nodes) | add
            elif type == "object" then
                1 + (if has("contents") then (.contents | count_nodes) else 0 end)
            else 0
            end;
        
        def calculate_depth:
            if type == "array" then
                if length == 0 then 0
                else map(calculate_depth) | max
                end
            elif type == "object" then
                if has("contents") then
                    1 + (.contents | calculate_depth)
                else 1
                end
            else 0
            end;
        
        def count_files:
            if type == "array" then
                map(count_files) | add
            elif type == "object" then
                (if .type == "file" then 1 else 0 end) +
                (if has("contents") then (.contents | count_files) else 0 end)
            else 0
            end;
        
        def estimate_tokens:
            # Rough estimation: avg 4 chars per token, 50 chars per node
            (count_nodes * 50) / 4;
        
        {
            "total_nodes": count_nodes,
            "max_depth": calculate_depth,
            "file_count": count_files,
            "directory_count": (count_nodes - count_files),
            "estimated_tokens": estimate_tokens,
            "signal_ratio": (count_files / count_nodes),
            "quality_score": ((count_files / count_nodes) * 0.4 + 
                            (if calculate_depth <= 8 then 0.3 else 0.1 end) +
                            (if estimate_tokens <= 32768 then 0.3 else 0.1 end))
        }
    ' "$json_file")
    
    echo "$metrics"
}

# Validate context engineering quality
validate_context_quality() {
    local json_file="$1"
    local min_quality="${2:-0.6}"
    
    local metrics
    metrics=$(calculate_context_metrics "$json_file")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local quality_score
    quality_score=$(echo "$metrics" | jq -r '.quality_score')
    
    local estimated_tokens
    estimated_tokens=$(echo "$metrics" | jq -r '.estimated_tokens')
    
    local max_depth
    max_depth=$(echo "$metrics" | jq -r '.max_depth')
    
    echo "$metrics" | jq .
    
    # Quality thresholds based on context engineering principles (using awk for math)
    local quality_check
    quality_check=$(echo "$quality_score $min_quality" | awk '{if ($1 >= $2) print "PASS"; else print "FAIL"}')
    
    if [[ "$quality_check" == "PASS" ]]; then
        log_success "✅ Context quality score: ${quality_score} (≥${min_quality})"
    else
        log_warning "⚠️  Context quality score: ${quality_score} (<${min_quality})"
        echo "   Consider reducing noise, increasing signal"
    fi
    
    if (( estimated_tokens <= 32768 )); then
        log_success "✅ Token budget: ${estimated_tokens} (≤32768)"
    else
        log_warning "⚠️  Token budget: ${estimated_tokens} (>32768)"
        echo "   Consider filtering or layered context"
    fi
    
    if (( max_depth <= 8 )); then
        log_success "✅ Max depth: ${max_depth} (≤8)"
    else
        log_warning "⚠️  Max depth: ${max_depth} (>8)"
        echo "   Consider flattening deep hierarchies"
    fi
    
    # Return 0 if all metrics pass (using awk for comparison)
    local all_checks_pass=true
    if [[ "$quality_check" != "PASS" ]]; then
        all_checks_pass=false
    fi
    if (( estimated_tokens > 32768 )); then
        all_checks_pass=false
    fi
    if (( max_depth > 8 )); then
        all_checks_pass=false
    fi
    
    if [[ "$all_checks_pass" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Export functions
export -f validate_ctx_schema
export -f calculate_context_metrics
export -f validate_context_quality 