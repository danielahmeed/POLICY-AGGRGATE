package com.mypolicy.implementation.config;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mypolicy.implementation.model.dto.MappingDTO;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Collections;
import java.util.Map;


@Component
public class MappingConfig {

    private static final Logger log = LoggerFactory.getLogger(MappingConfig.class);

    @Value("${mypolicy.mapping-config:classpath:mapping_config.json}")
    private Resource configResource;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private Map<String, Map<String, String>> mappings = Collections.emptyMap();

    @PostConstruct
    public void loadMappings() throws IOException {
        if (!configResource.exists()) {
            log.warn("Mapping config not found: {}", configResource);
            return;
        }
        mappings = objectMapper.readValue(
                configResource.getInputStream(),
                new TypeReference<>() {}
        );
        log.info("Loaded mapping config for collections: {}", mappings.keySet());
    }

    public Map<String, String> getMappingForCollection(String collectionName) {
        return mappings.getOrDefault(collectionName, Collections.emptyMap());
    }

    public Map<String, Map<String, String>> getAllMappings() {
        return Collections.unmodifiableMap(mappings);
    }

    public boolean hasMapping(String collectionName) {
        return mappings.containsKey(collectionName);
    }

    public MappingDTO getMappingDTO(String collectionName) {
        return new MappingDTO(getMappingForCollection(collectionName));
    }
}
