// Simple test script for SiteManager
const fs = require('fs');
const path = require('path');

console.log('=== SiteManager Test ===');
console.log('Testing SiteManager implementation...');

// Read the SiteManager file to check syntax
const siteManagerPath = path.join(__dirname, 'src/main/ets/service/spider/SiteManager.ets');

try {
  const content = fs.readFileSync(siteManagerPath, 'utf-8');
  
  // Check for basic syntax elements
  const checks = [
    { name: 'Class definition', pattern: /export class SiteManager/, required: true },
    { name: 'Singleton pattern', pattern: /private static instance/, required: true },
    { name: 'getInstance method', pattern: /public static getInstance/, required: true },
    { name: 'initialize method', pattern: /public async initialize/, required: true },
    { name: 'registerSite method', pattern: /public async registerSite/, required: true },
    { name: 'getSitesByType method', pattern: /public getSitesByType/, required: true },
    { name: 'getActiveSites method', pattern: /public async getActiveSites/, required: true },
    { name: 'callSiteMethod method', pattern: /public async callSiteMethod/, required: true },
    { name: 'SiteStatus enum', pattern: /export enum SiteStatus/, required: true },
    { name: 'SiteInfo interface', pattern: /export interface SiteInfo/, required: true }
  ];
  
  let passed = 0;
  let failed = 0;
  
  console.log('\n=== Checking syntax elements ===');
  
  for (const check of checks) {
    const found = check.pattern.test(content);
    if (found) {
      console.log(`✅ ${check.name}: Found`);
      passed++;
    } else {
      if (check.required) {
        console.log(`❌ ${check.name}: Missing (required)`);
        failed++;
      } else {
        console.log(`⚠️  ${check.name}: Missing (optional)`);
      }
    }
  }
  
  // Check for any obvious syntax errors
  console.log('\n=== Checking for syntax errors ===');
  
  // Check for duplicate class definitions
  const classMatches = content.match(/export class SiteManager/g);
  if (classMatches && classMatches.length > 1) {
    console.log(`❌ Found duplicate class definitions: ${classMatches.length}`);
    failed++;
  } else {
    console.log(`✅ No duplicate class definitions`);
  }
  
  // Check for proper closing braces
  const openBraces = (content.match(/{/g) || []).length;
  const closeBraces = (content.match(/}/g) || []).length;
  if (openBraces === closeBraces) {
    console.log(`✅ Balanced braces: ${openBraces} open, ${closeBraces} close`);
  } else {
    console.log(`❌ Unbalanced braces: ${openBraces} open, ${closeBraces} close`);
    failed++;
  }
  
  // Check for missing required imports
  const imports = [
    { name: 'Logger', pattern: /import Logger/, required: true },
    { name: 'Site', pattern: /import { Site/, required: true },
    { name: 'SiteDao', pattern: /import { SiteDao/, required: true },
    { name: 'LoaderType', pattern: /import { LoaderType/, required: true }
  ];
  
  for (const imp of imports) {
    const found = imp.pattern.test(content);
    if (found) {
      console.log(`✅ Import found: ${imp.name}`);
      passed++;
    } else {
      if (imp.required) {
        console.log(`❌ Import missing: ${imp.name} (required)`);
        failed++;
      } else {
        console.log(`⚠️  Import missing: ${imp.name} (optional)`);
      }
    }
  }
  
  console.log('\n=== Test Results ===');
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${failed}`);
  
  if (failed === 0) {
    console.log('\n🎉 All tests passed! SiteManager implementation looks good.');
  } else {
    console.log(`\n❌ ${failed} tests failed. Please check the SiteManager implementation.`);
  }
  
} catch (error) {
  console.error('❌ Error reading SiteManager file:', error.message);
  process.exit(1);
}

console.log('\n=== Test Complete ===');
