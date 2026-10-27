package com.anony.api.interceptors;

import static org.mockito.Mockito.verify;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;

@ExtendWith(MockitoExtension.class)
class WebMvcConfigurationTest {

  @Mock
  private RequestResponseLoggingInterceptor loggingInterceptor;

  @Mock
  private InterceptorRegistry interceptorRegistry;

  @Test
  @DisplayName("addInterceptors registers RequestResponseLoggingInterceptor")
  void addInterceptorsRegistersLoggingInterceptor() {
    WebMvcConfiguration configuration = new WebMvcConfiguration(loggingInterceptor);

    configuration.addInterceptors(interceptorRegistry);

    verify(interceptorRegistry).addInterceptor(loggingInterceptor);
  }
}
