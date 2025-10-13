/**
 * Web App - Lighthouse Performance Test
 * Tests web performance using Google Lighthouse
 */

import { test, expect } from '@playwright/test';
import lighthouse from 'lighthouse';
import * as chromeLauncher from 'chrome-launcher';

test.describe('Web App - Lighthouse Performance Tests', () => {
  const testUrl = process.env.TEST_URL || 'http://localhost:3000';

  test('should achieve >90 performance score', async () => {
    // Launch Chrome
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    // Run Lighthouse
    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);

    // Get performance score
    const performanceScore = runnerResult!.lhr.categories.performance.score! * 100;

    // Close Chrome
    await chrome.kill();

    // Assert performance score
    expect(performanceScore).toBeGreaterThanOrEqual(90);
    
    console.log(`Performance Score: ${performanceScore}`);
  }, 60000);

  test('should achieve >90 accessibility score', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['accessibility'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const accessibilityScore = runnerResult!.lhr.categories.accessibility.score! * 100;

    await chrome.kill();

    expect(accessibilityScore).toBeGreaterThanOrEqual(90);
    
    console.log(`Accessibility Score: ${accessibilityScore}`);
  }, 60000);

  test('should achieve >90 best practices score', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['best-practices'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const bestPracticesScore = runnerResult!.lhr.categories['best-practices'].score! * 100;

    await chrome.kill();

    expect(bestPracticesScore).toBeGreaterThanOrEqual(90);
    
    console.log(`Best Practices Score: ${bestPracticesScore}`);
  }, 60000);

  test('should achieve >90 SEO score', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['seo'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const seoScore = runnerResult!.lhr.categories.seo.score! * 100;

    await chrome.kill();

    expect(seoScore).toBeGreaterThanOrEqual(90);
    
    console.log(`SEO Score: ${seoScore}`);
  }, 60000);

  test('should have fast first contentful paint', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const fcpMetric = runnerResult!.lhr.audits['first-contentful-paint'];
    const fcpValue = fcpMetric.numericValue!;

    await chrome.kill();

    // FCP should be < 2 seconds (2000ms)
    expect(fcpValue).toBeLessThan(2000);
    
    console.log(`First Contentful Paint: ${fcpValue}ms`);
  }, 60000);

  test('should have fast largest contentful paint', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const lcpMetric = runnerResult!.lhr.audits['largest-contentful-paint'];
    const lcpValue = lcpMetric.numericValue!;

    await chrome.kill();

    // LCP should be < 2.5 seconds (2500ms)
    expect(lcpValue).toBeLessThan(2500);
    
    console.log(`Largest Contentful Paint: ${lcpValue}ms`);
  }, 60000);

  test('should have low total blocking time', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const tbtMetric = runnerResult!.lhr.audits['total-blocking-time'];
    const tbtValue = tbtMetric.numericValue!;

    await chrome.kill();

    // TBT should be < 300ms
    expect(tbtValue).toBeLessThan(300);
    
    console.log(`Total Blocking Time: ${tbtValue}ms`);
  }, 60000);

  test('should have low cumulative layout shift', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const clsMetric = runnerResult!.lhr.audits['cumulative-layout-shift'];
    const clsValue = clsMetric.numericValue!;

    await chrome.kill();

    // CLS should be < 0.1
    expect(clsValue).toBeLessThan(0.1);
    
    console.log(`Cumulative Layout Shift: ${clsValue}`);
  }, 60000);

  test('should have fast speed index', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const siMetric = runnerResult!.lhr.audits['speed-index'];
    const siValue = siMetric.numericValue!;

    await chrome.kill();

    // Speed Index should be < 3 seconds (3000ms)
    expect(siValue).toBeLessThan(3000);
    
    console.log(`Speed Index: ${siValue}ms`);
  }, 60000);

  test('should have fast time to interactive', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    const ttiMetric = runnerResult!.lhr.audits['interactive'];
    const ttiValue = ttiMetric.numericValue!;

    await chrome.kill();

    // TTI should be < 5 seconds (5000ms)
    expect(ttiValue).toBeLessThan(5000);
    
    console.log(`Time to Interactive: ${ttiValue}ms`);
  }, 60000);

  test('should have small bundle sizes', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    
    // Check JavaScript bundle size
    const jsSize = runnerResult!.lhr.audits['total-byte-weight'];
    const jsSizeValue = jsSize.numericValue!;

    await chrome.kill();

    // Total byte weight should be < 1MB (1000000 bytes)
    expect(jsSizeValue).toBeLessThan(1000000);
    
    console.log(`Total Byte Weight: ${jsSizeValue} bytes`);
  }, 60000);

  test('should use efficient caching', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    
    // Check cache policy
    const cacheAudit = runnerResult!.lhr.audits['uses-long-cache-ttl'];
    const cacheScore = cacheAudit.score!;

    await chrome.kill();

    // Cache score should be > 0.9
    expect(cacheScore).toBeGreaterThan(0.9);
    
    console.log(`Cache Policy Score: ${cacheScore * 100}`);
  }, 60000);

  test('should minimize unused JavaScript', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    
    // Check unused JavaScript
    const unusedJsAudit = runnerResult!.lhr.audits['unused-javascript'];
    const unusedJsScore = unusedJsAudit.score!;

    await chrome.kill();

    // Unused JavaScript score should be > 0.9
    expect(unusedJsScore).toBeGreaterThan(0.9);
    
    console.log(`Unused JavaScript Score: ${unusedJsScore * 100}`);
  }, 60000);

  test('should use modern image formats', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    
    // Check modern image formats
    const modernImagesAudit = runnerResult!.lhr.audits['modern-image-formats'];
    const modernImagesScore = modernImagesAudit.score!;

    await chrome.kill();

    // Modern image formats score should be > 0.9
    expect(modernImagesScore).toBeGreaterThan(0.9);
    
    console.log(`Modern Image Formats Score: ${modernImagesScore * 100}`);
  }, 60000);

  test('should have no critical request chains', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: 'json',
      onlyCategories: ['performance'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);
    
    // Check critical request chains
    const criticalChainAudit = runnerResult!.lhr.audits['critical-request-chains'];
    const chainDetails = criticalChainAudit.details;

    await chrome.kill();

    // Should have minimal critical request chains
    expect(criticalChainAudit.score).toBeGreaterThan(0.8);
    
    console.log(`Critical Request Chains: ${JSON.stringify(chainDetails)}`);
  }, 60000);

  test('should generate full Lighthouse report', async () => {
    const chrome = await chromeLauncher.launch({
      chromeFlags: ['--headless']
    });

    const options = {
      logLevel: 'info',
      output: ['json', 'html'],
      port: chrome.port
    };

    const runnerResult = await lighthouse(testUrl, options);

    await chrome.kill();

    // Print summary
    const scores = {
      performance: runnerResult!.lhr.categories.performance.score! * 100,
      accessibility: runnerResult!.lhr.categories.accessibility.score! * 100,
      bestPractices: runnerResult!.lhr.categories['best-practices'].score! * 100,
      seo: runnerResult!.lhr.categories.seo.score! * 100
    };

    console.log('\n=== Lighthouse Report Summary ===');
    console.log(`Performance:     ${scores.performance}`);
    console.log(`Accessibility:   ${scores.accessibility}`);
    console.log(`Best Practices:  ${scores.bestPractices}`);
    console.log(`SEO:             ${scores.seo}`);
    console.log('==================================\n');

    // All scores should be > 85
    Object.values(scores).forEach(score => {
      expect(score).toBeGreaterThan(85);
    });
  }, 60000);
});
