package com.anony.api.interceptors;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Spring MVC configuration registering HTTP request and response interceptors.
 */
@Configuration
public class WebMvcConfiguration implements WebMvcConfigurer {

  private final RequestResponseLoggingInterceptor requestResponseLoggingInterceptor;

  /**
   * Constructs the WebMvcConfiguration with the required logging interceptor.
   *
   * @param requestResponseLoggingInterceptor interceptor that logs HTTP requests and responses
   */
  public WebMvcConfiguration(
      RequestResponseLoggingInterceptor requestResponseLoggingInterceptor) {
    this.requestResponseLoggingInterceptor = requestResponseLoggingInterceptor;
  }

  @Override
  public void addInterceptors(InterceptorRegistry interceptorRegistry) {
    interceptorRegistry.addInterceptor(requestResponseLoggingInterceptor);
  }
}
